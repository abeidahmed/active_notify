require "test_helper"

class CallbacksTest < ActiveSupport::TestCase
  class History
    def self.entries
      @entries ||= []
    end

    def self.reset
      @entries = []
    end
  end

  class Email < ActiveNotify::Delivery
    def notify_now
      History.entries << :email_delivered
    end
  end

  class SMS < ActiveNotify::Delivery
    def notify_now
      History.entries << :sms_delivered
    end
  end

  class MockNotifier < ActiveNotify::Base
    notify_via :email, class_name: "CallbacksTest::Email"
    notify_via :sms, class_name: "CallbacksTest::SMS"

    before_notify -> { History.entries << :before_notify }
    after_notify -> { History.entries << :after_notify }

    before_notify -> { History.entries << :before_email }, on: :email
    after_notify -> { History.entries << :after_sms }, on: :sms
  end

  setup do
    History.reset
  end

  test "global before_notify and after_notify wrap all deliveries" do
    MockNotifier.notify_now

    assert_equal :before_notify, History.entries.first
    assert_equal :after_notify, History.entries.last
  end

  test "per-delivery callbacks wrap individual deliveries" do
    MockNotifier.notify_now

    assert_equal [
      :before_notify,
      :before_email,
      :email_delivered,
      :sms_delivered,
      :after_sms,
      :after_notify
    ], History.entries
  end

  class ConditionalNotifier < ActiveNotify::Base
    notify_via :email, class_name: "CallbacksTest::Email", if: :deliver_email?
    notify_via :sms, class_name: "CallbacksTest::SMS"

    before_notify -> { History.entries << :before_notify }
    after_notify -> { History.entries << :after_notify }

    before_notify -> { History.entries << :before_email }, on: :email
    after_notify -> { History.entries << :after_email }, on: :email
    before_notify -> { History.entries << :before_sms }, on: :sms

    private

    def deliver_email?
      false
    end
  end

  test "skipped delivery does not run per-delivery callbacks" do
    ConditionalNotifier.notify_now

    assert_equal [
      :before_notify,
      :before_sms,
      :sms_delivered,
      :after_notify
    ], History.entries
  end
end

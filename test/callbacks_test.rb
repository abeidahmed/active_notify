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

    before_notify :log_before_notify
    after_notify :log_after_notify

    before_notify :log_before_email, on: :email
    after_notify :log_after_sms, on: :sms

    private

    def log_before_notify
      History.entries << :before_notify
    end

    def log_after_notify
      History.entries << :after_notify
    end

    def log_before_email
      History.entries << :before_email
    end

    def log_after_sms
      History.entries << :after_sms
    end
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

    before_notify :log_before_notify
    after_notify :log_after_notify

    before_notify :log_before_email, on: :email
    after_notify :log_after_email, on: :email
    before_notify :log_before_sms, on: :sms

    private

    def deliver_email?
      false
    end

    def log_before_notify
      History.entries << :before_notify
    end

    def log_after_notify
      History.entries << :after_notify
    end

    def log_before_email
      History.entries << :before_email
    end

    def log_after_email
      History.entries << :after_email
    end

    def log_before_sms
      History.entries << :before_sms
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

  class SkipGlobalNotifier < MockNotifier
    skip_before_notify :log_before_notify
  end

  test "skip_before_notify removes a global before callback" do
    SkipGlobalNotifier.notify_now

    refute_includes History.entries, :before_notify
    assert_includes History.entries, :email_delivered
    assert_includes History.entries, :sms_delivered
  end

  class SkipPerDeliveryNotifier < MockNotifier
    skip_before_notify :log_before_email, on: :email
  end

  test "skip_before_notify with on: removes a per-delivery callback" do
    SkipPerDeliveryNotifier.notify_now

    refute_includes History.entries, :before_email
    assert_includes History.entries, :email_delivered
    assert_equal :before_notify, History.entries.first
  end

  class SkipAfterNotifier < MockNotifier
    skip_after_notify :log_after_sms, on: :sms
  end

  test "skip_after_notify with on: removes a per-delivery callback" do
    SkipAfterNotifier.notify_now

    refute_includes History.entries, :after_sms
    assert_includes History.entries, :sms_delivered
  end
end

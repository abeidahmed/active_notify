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

  class Email < ActiveNotify::Carrier
    def deliver_now
      History.entries << :email_delivered
    end
  end

  class SMS < ActiveNotify::Carrier
    def deliver_now
      History.entries << :sms_delivered
    end
  end

  class MockNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "CallbacksTest::Email"
    deliver_via :sms, class_name: "CallbacksTest::SMS"

    before_delivery :log_before_delivery
    after_delivery :log_after_delivery

    before_delivery :log_before_email, on: :email
    after_delivery :log_after_sms, on: :sms

    private

    def log_before_delivery
      History.entries << :before_delivery
    end

    def log_after_delivery
      History.entries << :after_delivery
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

  test "global before_delivery and after_delivery wrap all deliveries" do
    MockNotifier.deliver_now

    assert_equal :before_delivery, History.entries.first
    assert_equal :after_delivery, History.entries.last
  end

  test "per-delivery callbacks wrap individual deliveries" do
    MockNotifier.deliver_now

    assert_equal [
      :before_delivery,
      :before_email,
      :email_delivered,
      :sms_delivered,
      :after_sms,
      :after_delivery
    ], History.entries
  end

  class ConditionalNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "CallbacksTest::Email", if: :deliver_email?
    deliver_via :sms, class_name: "CallbacksTest::SMS"

    before_delivery :log_before_delivery
    after_delivery :log_after_delivery

    before_delivery :log_before_email, on: :email
    after_delivery :log_after_email, on: :email
    before_delivery :log_before_sms, on: :sms

    private

    def deliver_email?
      false
    end

    def log_before_delivery
      History.entries << :before_delivery
    end

    def log_after_delivery
      History.entries << :after_delivery
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
    ConditionalNotifier.deliver_now

    assert_equal [
      :before_delivery,
      :before_sms,
      :sms_delivered,
      :after_delivery
    ], History.entries
  end

  class SkipGlobalNotifier < MockNotifier
    skip_before_delivery :log_before_delivery
  end

  test "skip_before_delivery removes a global before callback" do
    SkipGlobalNotifier.deliver_now

    refute_includes History.entries, :before_delivery
    assert_includes History.entries, :email_delivered
    assert_includes History.entries, :sms_delivered
  end

  class SkipPerDeliveryNotifier < MockNotifier
    skip_before_delivery :log_before_email, on: :email
  end

  test "skip_before_delivery with on: removes a per-delivery callback" do
    SkipPerDeliveryNotifier.deliver_now

    refute_includes History.entries, :before_email
    assert_includes History.entries, :email_delivered
    assert_equal :before_delivery, History.entries.first
  end

  class SkipAfterNotifier < MockNotifier
    skip_after_delivery :log_after_sms, on: :sms
  end

  test "skip_after_delivery with on: removes a per-delivery callback" do
    SkipAfterNotifier.deliver_now

    refute_includes History.entries, :after_sms
    assert_includes History.entries, :sms_delivered
  end
end

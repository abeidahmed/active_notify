require "test_helper"

class NotifyTest < ActiveSupport::TestCase
  class MockNotifier < ActiveNotify::Base
    notify_via :email, class_name: "NotifyTest::Email"
    notify_via :sms, class_name: "NotifyTest::SMS"

    def self.history
      @history ||= []
    end

    def self.reset_history
      @history = []
    end
  end

  class Email
    def notify_later
      MockNotifier.history << [:email, :notify_later]
    end

    def notify_now
      MockNotifier.history << [:email, :notify_now]
    end
  end

  class SMS
    def notify_later
      MockNotifier.history << [:sms, :notify_later]
    end

    def notify_now
      MockNotifier.history << [:sms, :notify_now]
    end
  end

  setup do
    MockNotifier.reset_history
  end

  test "notify_later invokes the line's notify_later method" do
    MockNotifier.notify_later
    assert_equal [[:email, :notify_later], [:sms, :notify_later]], MockNotifier.history
  end

  test "notify_now invokes the line's notify method" do
    MockNotifier.notify_now
    assert_equal [[:email, :notify_now], [:sms, :notify_now]], MockNotifier.history
  end
end

require "test_helper"

class NotifyTest < ActiveSupport::TestCase
  class Email < ActiveNotify::Line
    def notify_later
      MockNotifier.history << [:email, :notify_later, params]
    end

    def notify_now
      MockNotifier.history << [:email, :notify_now, params]
    end
  end

  class SMS < ActiveNotify::Line
    def notify_later
      MockNotifier.history << [:sms, :notify_later, params]
    end

    def notify_now
      MockNotifier.history << [:sms, :notify_now, params]
    end
  end

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

  setup do
    MockNotifier.reset_history
  end

  test "notify_later invokes the line's notify_later method" do
    MockNotifier.notify_later

    assert_equal 2, MockNotifier.history.size
    assert_equal [[:email, :notify_later, {}], [:sms, :notify_later, {}]], MockNotifier.history
  end

  test "notify_now invokes the line's notify method" do
    MockNotifier.notify_now

    assert_equal 2, MockNotifier.history.size
    assert_equal [[:email, :notify_now, {}], [:sms, :notify_now, {}]], MockNotifier.history
  end

  test ".with params can be passed" do
    params = { sender_id: 1, recipient_id: 1 }
    MockNotifier.with(params).notify_later

    assert_equal 2, MockNotifier.history.size
    assert_equal params, MockNotifier.history.first.last
    assert_equal params, MockNotifier.history.last.last
  end

  test "params is accessible to the notifier instance" do
    params = { sender_id: 1 }
    notifier = MockNotifier.new(params)
    notifier.notify_later

    assert_equal params, notifier.params
  end
end

require "test_helper"

class NotifyTest < ActiveSupport::TestCase
  class Email < ActiveNotify::Line
    def notify_later(args)
      MockNotifier.history << { line: :email, method: :notify_later, params: params, args: args }
    end

    def notify_now
      MockNotifier.history << { line: :email, method: :notify_now, params: params }
    end
  end

  class SMS < ActiveNotify::Line
    def notify_later(args)
      MockNotifier.history << { line: :sms, method: :notify_later, params: params, args: args }
    end

    def notify_now
      MockNotifier.history << { line: :sms, method: :notify_now, params: params }
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

  test "#notify_later invokes the line's notify_later method" do
    MockNotifier.notify_later

    assert_equal 2, MockNotifier.history.size
    assert_equal [
      { line: :email, method: :notify_later, params: {}, args: {} },
      { line: :sms, method: :notify_later, params: {}, args: {} }
    ], MockNotifier.history
  end

  test "#notify_now invokes the line's notify method" do
    MockNotifier.notify_now

    assert_equal 2, MockNotifier.history.size
    assert_equal [
      { line: :email, method: :notify_now, params: {} },
      { line: :sms, method: :notify_now, params: {} }
    ], MockNotifier.history
  end

  test ".with params can be passed" do
    params = { sender_id: 1, recipient_id: 1 }
    MockNotifier.with(params).notify_later

    assert_equal 2, MockNotifier.history.size
    assert_equal params, MockNotifier.history.first[:params]
    assert_equal params, MockNotifier.history.last[:params]
  end

  test "params is accessible to the notifier instance" do
    params = { sender_id: 1 }
    notifier = MockNotifier.new(params)
    notifier.notify_later

    assert_equal params, notifier.params
  end

  test "#notify_later can accept arguments" do
    args = { wait: 5, queue: :priority }
    MockNotifier.notify_later(args)

    assert_equal args, MockNotifier.history.first[:args]
    assert_equal args, MockNotifier.history.last[:args]
  end
end

require "test_helper"

class NotifyTest < ActiveSupport::TestCase
  class Email < ActiveNotify::Delivery
    def notify_later(args)
      MockNotifier.history << { delivery: :email, method: :notify_later, params: params, args: args }
    end

    def notify_now
      MockNotifier.history << { delivery: :email, method: :notify_now, params: params }
    end
  end

  class SMS < ActiveNotify::Delivery
    def notify_later(args)
      MockNotifier.history << { delivery: :sms, method: :notify_later, params: params, args: args }
    end

    def notify_now
      MockNotifier.history << { delivery: :sms, method: :notify_now, params: params }
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

  test "#notify_later invokes the delivery's notify_later method" do
    MockNotifier.notify_later

    assert_equal 2, MockNotifier.history.size
    assert_equal [
      { delivery: :email, method: :notify_later, params: {}, args: {} },
      { delivery: :sms, method: :notify_later, params: {}, args: {} }
    ], MockNotifier.history
  end

  test "#notify_now invokes the delivery's notify method" do
    MockNotifier.notify_now

    assert_equal 2, MockNotifier.history.size
    assert_equal [
      { delivery: :email, method: :notify_now, params: {} },
      { delivery: :sms, method: :notify_now, params: {} }
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

  class NoopEmail < ActiveNotify::Delivery
  end

  class NoopNotifier < ActiveNotify::Base
    notify_via :email, class_name: "NotifyTest::NoopEmail"
  end

  test "does not raise an error if delivery does not define the notify methods" do
    assert_nothing_raised do
      NoopNotifier.notify_now
      NoopNotifier.notify_later
      NoopNotifier.notify_later(priority: :urgent)
    end
  end
end

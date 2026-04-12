require "test_helper"

class NotifyTest < ActiveSupport::TestCase
  class Email < ActiveNotify::Carrier
    def deliver_later(args = {})
      MockNotifier.history << { delivery: carrier_name, method: :deliver_later, params: params, args: args }
    end

    def deliver_now
      MockNotifier.history << { delivery: carrier_name, method: :deliver_now, params: params }
    end
  end

  class SMS < ActiveNotify::Carrier
    def deliver_later(args = {})
      MockNotifier.history << { delivery: carrier_name, method: :deliver_later, params: params, args: args }
    end

    def deliver_now
      MockNotifier.history << { delivery: carrier_name, method: :deliver_now, params: params }
    end
  end

  class MockNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "NotifyTest::Email"
    deliver_via :sms, class_name: "NotifyTest::SMS"

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

  test "#deliver_later invokes the delivery's deliver_later method" do
    MockNotifier.deliver_later

    assert_equal 2, MockNotifier.history.size
    assert_equal [
      { delivery: :email, method: :deliver_later, params: {}, args: {} },
      { delivery: :sms, method: :deliver_later, params: {}, args: {} }
    ], MockNotifier.history
  end

  test "#deliver_now invokes the delivery's notify method" do
    MockNotifier.deliver_now

    assert_equal 2, MockNotifier.history.size
    assert_equal [
      { delivery: :email, method: :deliver_now, params: {} },
      { delivery: :sms, method: :deliver_now, params: {} }
    ], MockNotifier.history
  end

  test ".with params can be passed" do
    params = { sender_id: 1, recipient_id: 1 }
    MockNotifier.with(params).deliver_later

    assert_equal 2, MockNotifier.history.size
    assert_equal params, MockNotifier.history.first[:params]
    assert_equal params, MockNotifier.history.last[:params]
  end

  test "params is accessible to the notifier instance" do
    params = { sender_id: 1 }
    notifier = MockNotifier.new(params)
    notifier.deliver_later

    assert_equal params, notifier.params
  end

  test "#deliver_later can accept arguments" do
    args = { wait: 5, queue: :priority }
    MockNotifier.deliver_later(args)

    assert_equal args, MockNotifier.history.first[:args]
    assert_equal args, MockNotifier.history.last[:args]
  end

  class NoopEmail < ActiveNotify::Carrier
  end

  class NoopNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "NotifyTest::NoopEmail"
  end

  test "does not raise an error if delivery does not define the notify methods" do
    assert_nothing_raised do
      NoopNotifier.deliver_now
      NoopNotifier.deliver_later
      NoopNotifier.deliver_later(priority: :urgent)
    end
  end
end

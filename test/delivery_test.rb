require "test_helper"

class DeliveryTest < ActiveSupport::TestCase
  class MockNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "TestCarrier"
    deliver_via :sms, class_name: "TestCarrier"
  end

  setup do
    TestHistory.reset
  end

  test "#deliver_later invokes the carrier's deliver_later method" do
    MockNotifier.deliver_later

    assert_equal 2, TestHistory.entries.size
    assert_equal [
      { carrier: :email, method: :deliver_later, params: {}, args: {} },
      { carrier: :sms, method: :deliver_later, params: {}, args: {} }
    ], TestHistory.entries
  end

  test "#deliver_now invokes the carrier's deliver_now method" do
    MockNotifier.deliver_now

    assert_equal 2, TestHistory.entries.size
    assert_equal [
      { carrier: :email, method: :deliver_now, params: {} },
      { carrier: :sms, method: :deliver_now, params: {} }
    ], TestHistory.entries
  end

  test ".with params can be passed" do
    params = { sender_id: 1, recipient_id: 1 }
    MockNotifier.with(params).deliver_later

    assert_equal 2, TestHistory.entries.size
    assert_equal params, TestHistory.entries.first[:params]
    assert_equal params, TestHistory.entries.last[:params]
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

    assert_equal args, TestHistory.entries.first[:args]
    assert_equal args, TestHistory.entries.last[:args]
  end

  class NoopNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "ActiveNotify::Carrier"
  end

  test "does not raise an error if carrier does not define the deliver methods" do
    assert_nothing_raised do
      NoopNotifier.deliver_now
      NoopNotifier.deliver_later
      NoopNotifier.deliver_later(priority: :urgent)
    end
  end
end

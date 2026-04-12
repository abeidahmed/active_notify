require "test_helper"

class ConditionalNotificationTest < ActiveSupport::TestCase
  class MockNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "TestCarrier", if: :deliver?
    deliver_via :sms, class_name: "TestCarrier", unless: :deliver?
    deliver_via :websocket, class_name: "TestCarrier", if: -> { deliver? }
    deliver_via :discord, class_name: "TestCarrier", unless: -> { deliver? }

    private

    def deliver?
      true
    end
  end

  class MockNotifierWhenFalse < ActiveNotify::Base
    deliver_via :email, class_name: "TestCarrier", if: :deliver?
    deliver_via :sms, class_name: "TestCarrier", unless: :deliver?
    deliver_via :websocket, class_name: "TestCarrier", if: -> { deliver? }
    deliver_via :discord, class_name: "TestCarrier", unless: -> { deliver? }

    private

    def deliver?
      false
    end
  end

  setup do
    TestHistory.reset
  end

  test "#deliver_now runs if: deliveries and skips unless: deliveries when condition is true" do
    MockNotifier.deliver_now

    assert_equal [:email, :websocket], TestHistory.carriers
  end

  test "#deliver_later runs if: deliveries and skips unless: deliveries when condition is true" do
    MockNotifier.deliver_later

    assert_equal [:email, :websocket], TestHistory.carriers
  end

  test "#deliver_now skips if: deliveries and runs unless: deliveries when condition is false" do
    MockNotifierWhenFalse.deliver_now

    assert_equal [:sms, :discord], TestHistory.carriers
  end

  test "#deliver_later skips if: deliveries and runs unless: deliveries when condition is false" do
    MockNotifierWhenFalse.deliver_later

    assert_equal [:sms, :discord], TestHistory.carriers
  end

  class MockNotifierWithLambdaBoolean < ActiveNotify::Base
    deliver_via :email, class_name: "TestCarrier", if: -> { true }
    deliver_via :sms, class_name: "TestCarrier", if: -> { false }
    deliver_via :websocket, class_name: "TestCarrier", unless: -> { true }
    deliver_via :discord, class_name: "TestCarrier", unless: -> { false }
  end

  test "if: and unless: work with literal boolean lambdas" do
    MockNotifierWithLambdaBoolean.deliver_now

    assert_equal [:email, :discord], TestHistory.carriers
  end
end

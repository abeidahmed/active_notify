require "test_helper"

class ConditionalNotificationTest < ActiveSupport::TestCase
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
      History.entries << :email
    end

    def deliver_later
      History.entries << :email
    end
  end

  class SMS < ActiveNotify::Carrier
    def deliver_now
      History.entries << :sms
    end

    def deliver_later
      History.entries << :sms
    end
  end

  class Websocket < ActiveNotify::Carrier
    def deliver_now
      History.entries << :websocket
    end

    def deliver_later
      History.entries << :websocket
    end
  end

  class Discord < ActiveNotify::Carrier
    def deliver_now
      History.entries << :discord
    end

    def deliver_later
      History.entries << :discord
    end
  end

  class MockNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "ConditionalNotificationTest::Email", if: :deliver?
    deliver_via :sms, class_name: "ConditionalNotificationTest::SMS", unless: :deliver?
    deliver_via :websocket, class_name: "ConditionalNotificationTest::Websocket", if: -> { deliver? }
    deliver_via :discord, class_name: "ConditionalNotificationTest::Discord", unless: -> { deliver? }

    private

    def deliver?
      true
    end
  end

  class MockNotifierWhenFalse < ActiveNotify::Base
    deliver_via :email, class_name: "ConditionalNotificationTest::Email", if: :deliver?
    deliver_via :sms, class_name: "ConditionalNotificationTest::SMS", unless: :deliver?
    deliver_via :websocket, class_name: "ConditionalNotificationTest::Websocket", if: -> { deliver? }
    deliver_via :discord, class_name: "ConditionalNotificationTest::Discord", unless: -> { deliver? }

    private

    def deliver?
      false
    end
  end

  setup do
    History.reset
  end

  test "#deliver_now runs if: deliveries and skips unless: deliveries when condition is true" do
    MockNotifier.deliver_now

    assert_equal [:email, :websocket], History.entries
  end

  test "#deliver_later runs if: deliveries and skips unless: deliveries when condition is true" do
    MockNotifier.deliver_later

    assert_equal [:email, :websocket], History.entries
  end

  test "#deliver_now skips if: deliveries and runs unless: deliveries when condition is false" do
    MockNotifierWhenFalse.deliver_now

    assert_equal [:sms, :discord], History.entries
  end

  test "#deliver_later skips if: deliveries and runs unless: deliveries when condition is false" do
    MockNotifierWhenFalse.deliver_later

    assert_equal [:sms, :discord], History.entries
  end

  class MockNotifierWithLambdaBoolean < ActiveNotify::Base
    deliver_via :email, class_name: "ConditionalNotificationTest::Email", if: -> { true }
    deliver_via :sms, class_name: "ConditionalNotificationTest::SMS", if: -> { false }
    deliver_via :websocket, class_name: "ConditionalNotificationTest::Websocket", unless: -> { true }
    deliver_via :discord, class_name: "ConditionalNotificationTest::Discord", unless: -> { false }
  end

  test "if: and unless: work with literal boolean lambdas" do
    MockNotifierWithLambdaBoolean.deliver_now

    assert_equal [:email, :discord], History.entries
  end
end

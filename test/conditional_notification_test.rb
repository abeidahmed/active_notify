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

  class Email < ActiveNotify::Delivery
    def notify_now
      History.entries << :email
    end

    def notify_later
      History.entries << :email
    end
  end

  class SMS < ActiveNotify::Delivery
    def notify_now
      History.entries << :sms
    end

    def notify_later
      History.entries << :sms
    end
  end

  class Websocket < ActiveNotify::Delivery
    def notify_now
      History.entries << :websocket
    end

    def notify_later
      History.entries << :websocket
    end
  end

  class Discord < ActiveNotify::Delivery
    def notify_now
      History.entries << :discord
    end

    def notify_later
      History.entries << :discord
    end
  end

  class MockNotifier < ActiveNotify::Base
    notify_via :email, class_name: "ConditionalNotificationTest::Email", if: :deliver?
    notify_via :sms, class_name: "ConditionalNotificationTest::SMS", unless: :deliver?
    notify_via :websocket, class_name: "ConditionalNotificationTest::Websocket", if: -> { deliver? }
    notify_via :discord, class_name: "ConditionalNotificationTest::Discord", unless: -> { deliver? }

    private

    def deliver?
      true
    end
  end

  class MockNotifierWhenFalse < ActiveNotify::Base
    notify_via :email, class_name: "ConditionalNotificationTest::Email", if: :deliver?
    notify_via :sms, class_name: "ConditionalNotificationTest::SMS", unless: :deliver?
    notify_via :websocket, class_name: "ConditionalNotificationTest::Websocket", if: -> { deliver? }
    notify_via :discord, class_name: "ConditionalNotificationTest::Discord", unless: -> { deliver? }

    private

    def deliver?
      false
    end
  end

  setup do
    History.reset
  end

  test "#notify_now runs if: deliveries and skips unless: deliveries when condition is true" do
    MockNotifier.notify_now

    assert_equal [:email, :websocket], History.entries
  end

  test "#notify_later runs if: deliveries and skips unless: deliveries when condition is true" do
    MockNotifier.notify_later

    assert_equal [:email, :websocket], History.entries
  end

  test "#notify_now skips if: deliveries and runs unless: deliveries when condition is false" do
    MockNotifierWhenFalse.notify_now

    assert_equal [:sms, :discord], History.entries
  end

  test "#notify_later skips if: deliveries and runs unless: deliveries when condition is false" do
    MockNotifierWhenFalse.notify_later

    assert_equal [:sms, :discord], History.entries
  end

  class MockNotifierWithLambdaBoolean < ActiveNotify::Base
    notify_via :email, class_name: "ConditionalNotificationTest::Email", if: -> { true }
    notify_via :sms, class_name: "ConditionalNotificationTest::SMS", if: -> { false }
    notify_via :websocket, class_name: "ConditionalNotificationTest::Websocket", unless: -> { true }
    notify_via :discord, class_name: "ConditionalNotificationTest::Discord", unless: -> { false }
  end

  test "if: and unless: work with literal boolean lambdas" do
    MockNotifierWithLambdaBoolean.notify_now

    assert_equal [:email, :discord], History.entries
  end
end

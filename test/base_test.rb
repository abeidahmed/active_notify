require "test_helper"

class BaseTest < ActiveSupport::TestCase
  class Generic < ActiveNotify::Carrier
  end

  class Email < ActiveNotify::Carrier
    def deliver_now
      raise ArgumentError unless notifier.is_a?(ActiveNotify::Base)
      ChildNotifier.history << :email
    end
  end

  class BaseNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "BaseTest::Generic"
    deliver_via :sms, class_name: "BaseTest::Generic"
  end

  class ChildNotifier < BaseNotifier
    deliver_via :action_cable, class_name: "BaseTest::Generic"
    deliver_via :email, class_name: "BaseTest::Email"

    def self.history
      @history ||= []
    end

    def self.reset_history
      @history = []
    end
  end

  setup do
    ChildNotifier.reset_history
  end

  test "defines carriers" do
    assert_equal [:email, :sms], BaseNotifier.carriers.keys
  end

  test "inherits carriers from superclass" do
    assert_equal [:email, :sms, :action_cable], ChildNotifier.carriers.keys
  end

  test "carrier definition overrides parent carrier" do
    ChildNotifier.deliver_now

    assert_equal 1, ChildNotifier.history.size
    assert_equal [:email], ChildNotifier.history
  end
end

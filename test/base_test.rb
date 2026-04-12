require "test_helper"

class BaseTest < ActiveSupport::TestCase
  class BaseNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "ActiveNotify::Carrier"
    deliver_via :sms, class_name: "ActiveNotify::Carrier"
  end

  class ChildNotifier < BaseNotifier
    deliver_via :action_cable, class_name: "ActiveNotify::Carrier"
    deliver_via :email, class_name: "TestCarrier"
  end

  setup do
    TestHistory.reset
  end

  test "defines carriers" do
    assert_equal [:email, :sms], BaseNotifier.carriers.keys
  end

  test "inherits carriers from superclass" do
    assert_equal [:email, :sms, :action_cable], ChildNotifier.carriers.keys
  end

  test "carrier definition overrides parent carrier" do
    ChildNotifier.deliver_now

    assert_equal 1, TestHistory.entries.size
    assert_equal :email, TestHistory.entries.first[:carrier]
  end
end

require "test_helper"

class BaseTest < ActiveSupport::TestCase
  class BaseNotifier < ActiveNotify::Base
    notify_via :email
    notify_via :sms
  end

  class ChildNotifier < BaseNotifier
    notify_via :action_cable
  end

  test "defines deliveries" do
    assert_equal [:email, :sms], BaseNotifier.deliveries.keys
  end

  test "inherits deliveries from superclass" do
    assert_equal [:email, :sms, :action_cable], ChildNotifier.deliveries.keys
  end
end

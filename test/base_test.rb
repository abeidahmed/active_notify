require "test_helper"

class BaseTest < ActiveSupport::TestCase
  class BaseNotifier < ActiveNotify::Base
    deliver_via :email
    deliver_via :sms
  end

  class ChildNotifier < BaseNotifier
    deliver_via :action_cable
  end

  test "defines carriers" do
    assert_equal [:email, :sms], BaseNotifier.carriers.keys
  end

  test "inherits carriers from superclass" do
    assert_equal [:email, :sms, :action_cable], ChildNotifier.carriers.keys
  end
end

require "test_helper"

class BaseTest < ActiveSupport::TestCase
  class BaseNotifier < ActiveNotify::Base
    notify_via :email
    notify_via :sms
  end

  class ChildNotifier < BaseNotifier
    notify_via :action_cable
  end

  test "defines lines" do
    assert_equal [:email, :sms], BaseNotifier.lines.keys
  end

  test "inherits lines from superclass" do
    assert_equal [:email, :sms, :action_cable], ChildNotifier.lines.keys
  end
end

require "test_helper"
require "active_notify/testing"

class MinitestTest < ActiveSupport::TestCase
  include ActiveNotify::TestHelper

  class MockNotifier < ActiveNotify::Base
    deliver_via :email

    class Email < ActiveNotify::Carrier; end
  end

  test "setup sets correct delivery options" do
    assert ActiveNotify::TestDelivery.enabled
    assert_equal [], ActiveNotify::TestDelivery.deliveries
  end

  test "assert_notify_deliveries" do
    assert_notify_deliveries 0
    MockNotifier.deliver_now
    assert_notify_deliveries 1
  end

  test "assert_notify_deliveries with block" do
    assert_nothing_raised do
      assert_notify_deliveries 1 do
        MockNotifier.deliver_now
      end
    end
  end
end

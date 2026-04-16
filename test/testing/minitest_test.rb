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

  test "capture_notify_deliveries" do
    assert_nothing_raised do
      deliveries = capture_notify_deliveries do
        MockNotifier.deliver_now
      end
      delivery = deliveries.first
      assert_equal :email, delivery[:carrier_name]
      assert_equal :deliver_now, delivery[:method_name]
      assert_equal({}, delivery[:params])
      assert_nil delivery[:args]

      deliveries = capture_notify_deliveries do
        MockNotifier.deliver_now
        MockNotifier.deliver_now
      end
      assert_instance_of Array, deliveries
      assert_equal MockNotifier, deliveries.first[:notifier_class]
      assert_equal MockNotifier, deliveries.last[:notifier_class]
    end
  end

  test "assert_notify_deliveries with enqueued deliveries" do
    assert_nothing_raised do
      assert_notify_deliveries 1 do
        MockNotifier.deliver_later
      end
    end
  end

  test "repeated assert_notify_deliveries calls" do
    assert_nothing_raised do
      assert_notify_deliveries 1 do
        MockNotifier.deliver_now
      end
    end

    assert_nothing_raised do
      assert_notify_deliveries 2 do
        MockNotifier.deliver_now
        MockNotifier.deliver_now
      end
    end
  end

  test "assert_notify_deliveries with no block" do
    assert_nothing_raised do
      MockNotifier.deliver_now
      assert_notify_deliveries 1
    end

    assert_nothing_raised do
      MockNotifier.deliver_now
      MockNotifier.deliver_now
      assert_notify_deliveries 3
    end
  end

  test "assert_no_notify_deliveries" do
    assert_nothing_raised do
      assert_no_notify_deliveries do
        MockNotifier
      end
    end
  end

  test "assert_notify_deliveries message" do
    MockNotifier.deliver_now
    error = assert_raise ActiveSupport::TestCase::Assertion do
      assert_notify_deliveries 2 do
        MockNotifier.deliver_now
      end
    end

    assert_match "Expected: 2", error.message
    assert_match "Actual: 1", error.message
  end

  test "assert_no_notify_deliveries message" do
    error = assert_raise ActiveSupport::TestCase::Assertion do
      assert_no_notify_deliveries do
        MockNotifier.deliver_now
      end
    end

    assert_match(/0 .* but 1/, error.message)
  end

  test "assert_enqueued_notify_deliveries" do
    assert_nothing_raised do
      assert_enqueued_notify_deliveries 0
      MockNotifier.deliver_now
      MockNotifier.deliver_later
      assert_enqueued_notify_deliveries 1
      MockNotifier.deliver_later
      assert_enqueued_notify_deliveries 2
    end
  end

  test "assert_enqueued_notify_deliveries with block" do
    assert_nothing_raised do
      assert_enqueued_notify_deliveries 1 do
        MockNotifier.deliver_later
      end
    end
  end

  test "assert_enqueued_notify_deliveries for deliver_now" do
    assert_nothing_raised do
      assert_enqueued_notify_deliveries 0 do
        MockNotifier.deliver_now
      end
    end
  end

  test "assert_no_enqueued_notify_deliveries" do
    assert_nothing_raised do
      assert_no_enqueued_notify_deliveries do
        MockNotifier.deliver_now
      end
    end
  end

  test "assert_no_enqueued_notify_deliveries failure" do
    error = assert_raise ActiveSupport::TestCase::Assertion do
      assert_no_enqueued_notify_deliveries do
        MockNotifier.deliver_later
      end
    end

    assert_match(/0 .* but 1/, error.message)
  end

  test "assert_enqueued_notify_deliveries message" do
    MockNotifier.deliver_later
    error = assert_raise ActiveSupport::TestCase::Assertion do
      assert_enqueued_notify_deliveries 2 do
        MockNotifier.deliver_later
      end
    end

    assert_match "Expected: 2", error.message
    assert_match "Actual: 1", error.message
  end
end

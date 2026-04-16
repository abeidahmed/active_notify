# frozen_string_literal: true

module ActiveNotify
  module TestHelper
    extend ActiveSupport::Concern

    included do
      setup :setup_test_deliveries
      teardown :teardown_test_deliveries
    end

    def assert_notify_deliveries(number, &block)
      if block
        diff = capture_notify_deliveries(&block).size
        assert_equal number, diff, "#{number} notify deliveries expected, but #{diff} were delivered"
      else
        assert_equal number, TestDelivery.deliveries.size
      end
    end

    def assert_no_notify_deliveries(&)
      assert_notify_deliveries(0, &)
    end

    def assert_enqueued_notify_deliveries(number, &block)
      handler = ->(delivery) { delivery[:method_name] == :deliver_later }

      if block
        diff = capture_notify_deliveries(&block).filter(&handler).size
        assert_equal number, diff, "#{number} notify deliveries expected, but #{diff} were enqueued"
      else
        assert_equal number, TestDelivery.deliveries.filter(&handler).size
      end
    end

    def assert_no_enqueued_notify_deliveries(&)
      assert_enqueued_notify_deliveries(0, &)
    end

    def capture_notify_deliveries(&block)
      original_count = TestDelivery.deliveries.size
      block.call
      new_count = TestDelivery.deliveries.size
      diff = new_count - original_count
      TestDelivery.deliveries.last(diff)
    end

    private

    def setup_test_deliveries
      @old_enabled = TestDelivery.enabled
      TestDelivery.enabled = true
      TestDelivery.deliveries.clear
    end

    def teardown_test_deliveries
      TestDelivery.enabled = @old_enabled
      TestDelivery.deliveries.clear
    end
  end
end

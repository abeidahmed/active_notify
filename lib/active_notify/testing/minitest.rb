# frozen_string_literal: true

module ActiveNotify
  module TestHelper
    extend ActiveSupport::Concern

    included do
      setup :setup_test_deliveries
      teardown :teardown_test_deliveries
    end

    def assert_notify_deliveries(number, &block)
      _assert_notify_deliveries(number, verb: "delivered", &block)
    end

    def assert_no_notify_deliveries(&)
      assert_notify_deliveries(0, &)
    end

    def assert_enqueued_notify_deliveries(number, &block)
      _assert_notify_deliveries(number, verb: "enqueued", filter: ENQUEUED_FILTER, &block)
    end

    def assert_no_enqueued_notify_deliveries(&)
      assert_enqueued_notify_deliveries(0, &)
    end

    def capture_notify_deliveries
      raise ArgumentError, "block is required" unless block_given?

      original_count = TestDelivery.deliveries.size
      yield
      TestDelivery.deliveries[original_count..] || []
    end

    private

    ENQUEUED_FILTER = ->(delivery) { delivery[:method_name] == :deliver_later }

    def setup_test_deliveries
      @old_enabled = TestDelivery.enabled
      TestDelivery.enabled = true
      TestDelivery.deliveries.clear
    end

    def teardown_test_deliveries
      TestDelivery.enabled = @old_enabled
      TestDelivery.deliveries.clear
    end

    def _assert_notify_deliveries(number, verb:, filter: nil, &block)
      source = block ? capture_notify_deliveries(&block) : TestDelivery.deliveries
      actual = filter ? source.count(&filter) : source.size
      assert_equal number, actual, "#{number} notify deliveries expected, but #{actual} were #{verb}"
    end
  end
end

# frozen_string_literal: true

module ActiveNotify
  # = Active \Notify \TestHelper
  #
  # Provides assertions and helpers for testing notifiers. When included
  # into a test case, deliveries made via {Base#deliver_now}[rdoc-ref:Base.deliver_now]
  # and {Base#deliver_later}[rdoc-ref:Base.deliver_later] are captured
  # instead of being dispatched to their carriers, so tests can assert on
  # what was sent without triggering side effects.
  #
  #   class CommentNotifierTest < ActiveSupport::TestCase
  #     include ActiveNotify::TestHelper
  #
  #     test "notifies on new comment" do
  #       assert_notify_deliveries 1 do
  #         CommentNotifier.with(user: user).deliver_now
  #       end
  #     end
  #   end
  module TestHelper
    extend ActiveSupport::Concern

    included do
      setup :setup_test_deliveries
      teardown :teardown_test_deliveries
    end

    # Asserts that the number of notifications delivered synchronously
    # (via +deliver_now+) matches the given number.
    #
    #   def test_notify_deliveries
    #     assert_notify_deliveries 0
    #     CommentNotifier.deliver_now
    #     assert_notify_deliveries 1
    #     CommentNotifier.deliver_now
    #     assert_notify_deliveries 2
    #   end
    #
    # If a block is passed, that block should cause the specified number
    # of notifications to be delivered.
    #
    #   def test_notify_deliveries_again
    #     assert_notify_deliveries 1 do
    #       CommentNotifier.deliver_now
    #     end
    #
    #     assert_notify_deliveries 2 do
    #       CommentNotifier.deliver_now
    #       AnotherNotifier.deliver_now
    #     end
    #   end
    def assert_notify_deliveries(number, &block)
      _assert_notify_deliveries(number, verb: "delivered", &block)
    end

    # Asserts that no notifications were delivered synchronously
    # (via +deliver_now+).
    #
    #   def test_notifications_not_delivered
    #     assert_no_notify_deliveries
    #   end
    #
    # If a block is passed, that block should not cause any notifications
    # to be delivered.
    #
    #   def test_notifications_not_delivered_in_block
    #     assert_no_notify_deliveries do
    #       CommentNotifier.deliver_later
    #     end
    #   end
    def assert_no_notify_deliveries(&)
      assert_notify_deliveries(0, &)
    end

    # Asserts that the number of notifications enqueued for background
    # delivery (via +deliver_later+) matches the given number.
    #
    #   def test_notify_deliveries_enqueued
    #     assert_enqueued_notify_deliveries 0
    #     CommentNotifier.deliver_later
    #     assert_enqueued_notify_deliveries 1
    #     CommentNotifier.deliver_later
    #     assert_enqueued_notify_deliveries 2
    #   end
    #
    # If a block is passed, that block should cause the specified number
    # of notifications to be enqueued.
    #
    #   def test_notify_deliveries_enqueued_again
    #     assert_enqueued_notify_deliveries 1 do
    #       CommentNotifier.deliver_later
    #     end
    #
    #     assert_enqueued_notify_deliveries 2 do
    #       CommentNotifier.deliver_later
    #       AnotherNotifier.deliver_later
    #     end
    #   end
    def assert_enqueued_notify_deliveries(number, &block)
      _assert_notify_deliveries(number, verb: "enqueued", filter: ENQUEUED_FILTER, &block)
    end

    # Asserts that no notifications were enqueued for background delivery
    # (via +deliver_later+).
    #
    #   def test_notifications_not_enqueued
    #     assert_no_enqueued_notify_deliveries
    #   end
    #
    # If a block is passed, that block should not cause any notifications
    # to be enqueued.
    #
    #   def test_notifications_not_enqueued_in_block
    #     assert_no_enqueued_notify_deliveries do
    #       CommentNotifier.deliver_now
    #     end
    #   end
    def assert_no_enqueued_notify_deliveries(&)
      assert_enqueued_notify_deliveries(0, &)
    end

    # Returns an array of the notifications recorded inside the block.
    # Each entry is a hash with +:notifier_class+, +:carrier_name+,
    # +:method_name+ (+:deliver_now+ or +:deliver_later+), +:params+,
    # and +:args+.
    #
    #   def test_capture_notify_deliveries
    #     deliveries = capture_notify_deliveries do
    #       CommentNotifier.with(user: user).deliver_now
    #     end
    #
    #     assert_equal 1, deliveries.size
    #     assert_equal :deliver_now, deliveries.first[:method_name]
    #     assert_equal({ user: user }, deliveries.first[:params])
    #   end
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

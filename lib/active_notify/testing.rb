# frozen_string_literal: true

module ActiveNotify
  class TestDelivery
    cattr_accessor :enabled, default: false
    cattr_accessor :deliveries, instance_writer: false, default: []

    class << self
      def track(delivery)
        deliveries << delivery
      end
    end

    module Behavior
      def deliver_now
        perform_deliveries do |instance|
          TestDelivery.track(
            notifier_class: self.class,
            carrier_name: instance.carrier_name,
            method: :deliver_now,
            params:,
            args: nil
          )
        end
      end

      def deliver_later(args = {})
      end
    end
  end
end

ActiveNotify::Base.prepend(ActiveNotify::TestDelivery::Behavior)

require_relative "testing/minitest" if defined?(Minitest::Assertions)

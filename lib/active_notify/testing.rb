# frozen_string_literal: true

module ActiveNotify
  class TestDelivery
    cattr_accessor :enabled, default: false
    cattr_accessor :deliveries, instance_writer: false, default: []

    class << self
      def track(delivery)
        deliveries << delivery
      end

      def enabled?
        enabled
      end
    end

    module Behavior
      def deliver_now
        return super unless TestDelivery.enabled?

        perform_deliveries do |instance|
          TestDelivery.track(
            notifier_class: self.class,
            carrier_name: instance.carrier_name,
            method_name: :deliver_now,
            params:,
            args: nil
          )
        end
      end

      def deliver_later(args = {})
        return super unless TestDelivery.enabled?

        perform_deliveries do |instance|
          TestDelivery.track(
            notifier_class: self.class,
            carrier_name: instance.carrier_name,
            method_name: :deliver_later,
            params:,
            args:
          )
        end
      end
    end
  end
end

ActiveNotify::Base.prepend(ActiveNotify::TestDelivery::Behavior)

require_relative "testing/minitest" if defined?(Minitest::Assertions)

require "active_support/core_ext/class/attribute"
require_relative "delivery_config"

module ActiveNotify
  class Base
    class_attribute :deliveries, instance_writer: false, default: {}

    class << self
      def notify_via(delivery_name, options = {})
        self.deliveries = deliveries.merge(delivery_name => DeliveryConfig.new(delivery_name, options))
      end

      def notify_now
        new.notify_now
      end

      def notify_later(...)
        new.notify_later(...)
      end

      def with(params)
        new(params)
      end
    end

    attr_reader :params

    def initialize(params = {})
      @params = params
    end

    def notify_now
      perform_deliveries do |instance|
        instance.notify_now
      end
    end

    def notify_later(*args)
      perform_deliveries do |instance|
        instance.notify_later(*args)
      end
    end

    private

    def perform_deliveries
      deliveries.each do |_name, config|
        next unless config.notify?(self)
        yield config.constant.new(self)
      end
    end
  end
end

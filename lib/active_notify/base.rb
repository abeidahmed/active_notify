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
      deliveries.each do |_name, config|
        config.constant.new(self).notify_now
      end
    end

    def notify_later(args = {})
      deliveries.each do |_name, config|
        config.constant.new(self).notify_later(args)
      end
    end
  end
end

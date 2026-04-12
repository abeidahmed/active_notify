require "active_support/core_ext/class/attribute"
require_relative "carrier_descriptor"
require_relative "callbacks"

module ActiveNotify
  class Base
    include Callbacks

    class_attribute :carriers, instance_writer: false, default: {}

    class << self
      def deliver_via(carrier_name, options = {})
        self.carriers = carriers.merge(carrier_name => CarrierDescriptor.new(carrier_name, options))
        define_carrier_callbacks(carrier_name)
      end

      def deliver_now
        new.deliver_now
      end

      def deliver_later(...)
        new.deliver_later(...)
      end

      def with(params)
        new(params)
      end
    end

    attr_reader :params

    def initialize(params = {})
      @params = params
    end

    def deliver_now
      perform_deliveries do |instance|
        instance.deliver_now
      end
    end

    def deliver_later(*args)
      perform_deliveries do |instance|
        instance.deliver_later(*args)
      end
    end

    private

    def perform_deliveries
      run_delivery_callbacks do
        carriers.each do |name, config|
          next unless config.deliver?(self)

          run_carrier_callbacks(name) do
            yield config.constant.new(self)
          end
        end
      end
    end
  end
end

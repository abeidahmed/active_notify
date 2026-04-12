require "active_support/callbacks"
require "active_support/concern"

module ActiveNotify
  module Callbacks
    extend ActiveSupport::Concern
    include ActiveSupport::Callbacks

    included do
      define_callbacks :delivery
    end

    class_methods do
      def define_carrier_callbacks(carrier_name)
        define_callbacks carrier_name
      end

      %i[before after around].each do |kind|
        define_method "#{kind}_delivery" do |*names, on: :delivery, **options, &block|
          names.each do |name|
            set_callback on, kind, name, options
          end

          set_callback on, kind, block, options if block
        end

        define_method "skip_#{kind}_delivery" do |*names, on: :delivery, **options|
          names.each do |name|
            skip_callback on, kind, name, options
          end
        end
      end
    end

    private

    def run_delivery_callbacks(&)
      run_callbacks(:delivery, &)
    end

    def run_carrier_callbacks(carrier_name, &)
      run_callbacks(carrier_name, &)
    end
  end
end

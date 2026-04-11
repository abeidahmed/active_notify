require "active_support/callbacks"
require "active_support/concern"

module ActiveNotify
  module Callbacks
    extend ActiveSupport::Concern
    include ActiveSupport::Callbacks

    included do
      define_callbacks :notify
    end

    class_methods do
      def define_delivery_callbacks(delivery_name)
        define_callbacks delivery_name
      end

      %i[before after around].each do |kind|
        define_method "#{kind}_notify" do |*names, on: :notify, **options, &block|
          names.each do |name|
            set_callback on, kind, name, options
          end

          set_callback on, kind, block, options if block
        end
      end
    end

    private

    def run_notify_callbacks(&)
      run_callbacks(:notify, &)
    end

    def run_delivery_callbacks(delivery_name, &)
      run_callbacks(delivery_name, &)
    end
  end
end

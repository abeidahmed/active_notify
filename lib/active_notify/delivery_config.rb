module ActiveNotify
  class DeliveryConfig
    attr_reader :name, :options

    def initialize(delivery_name, options = {})
      @delivery_name = delivery_name
      @options = options
    end

    def constant
      options.fetch(:class_name).constantize
    end
  end
end

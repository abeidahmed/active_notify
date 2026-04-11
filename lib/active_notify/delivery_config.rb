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

    def notify?(context)
      return false if options.key?(:if) && !evaluate(:if, context)
      return false if options.key?(:unless) && evaluate(:unless, context)
      true
    end

    private

    def evaluate(kind, context)
      condition = options[kind]

      if condition.respond_to?(:call, true)
        context.instance_exec(&condition)
      elsif condition.is_a?(Symbol)
        context.send(condition)
      else
        condition
      end
    end
  end
end

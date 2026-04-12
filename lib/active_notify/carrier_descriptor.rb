module ActiveNotify
  class CarrierDescriptor
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def constant
      options.fetch(:class_name).constantize
    end

    def deliver?(context)
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

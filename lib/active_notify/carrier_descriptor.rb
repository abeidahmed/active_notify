module ActiveNotify
  class CarrierDescriptor
    RESERVED_KEYS = %i[class_name if unless].freeze

    attr_reader :args

    def initialize(options = {})
      @options = options.extract!(*RESERVED_KEYS)
      @class_name = @options[:class_name]
      @args = options
    end

    def constant
      raise ArgumentError unless @class_name
      @class_name.constantize
    end

    def deliver?(context)
      return false if options.key?(:if) && !evaluate(:if, context)
      return false if options.key?(:unless) && evaluate(:unless, context)
      true
    end

    private

    attr_reader :options

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

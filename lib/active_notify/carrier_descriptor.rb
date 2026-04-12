module ActiveNotify
  class CarrierDescriptor
    RESERVED_KEYS = %i[class_name if unless].freeze

    attr_reader :name

    def initialize(name, notifier_class, options = {})
      @name = name
      @notifier_class = notifier_class
      @options = options.extract!(*RESERVED_KEYS)
      @args = options
    end

    def constant
      return @options[:class_name].constantize if @options[:class_name]
      @notifier_class.const_get(name.to_s.classify)
    end

    def args(context)
      @args.transform_values { |value| compute(value, context) }
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
        compute(condition, context)
      elsif condition.is_a?(Symbol)
        context.send(condition)
      else
        condition
      end
    end

    def compute(value, context)
      return value unless value.respond_to?(:call, true)

      if value.arity == 1
        value.call(context)
      else
        context.instance_exec(&value)
      end
    end
  end
end

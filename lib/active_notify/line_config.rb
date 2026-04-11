module ActiveNotify
  class LineConfig
    attr_reader :name, :options

    def initialize(line_name, options = {})
      @line_name = line_name
      @options = options
    end

    def constant
      options.fetch(:class_name).constantize
    end
  end
end

module ActiveNotify
  class LineConfig
    def initialize(line_name, options = {})
      @line_name = line_name
      @options = options
    end
  end
end

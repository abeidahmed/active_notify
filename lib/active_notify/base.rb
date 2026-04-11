require "active_support/core_ext/class/attribute"
require_relative "line_config"

module ActiveNotify
  class Base
    class_attribute :lines, instance_writer: false, default: {}

    class << self
      def notify_via(line_name, options = {})
        self.lines = lines.merge(line_name => LineConfig.new(line_name, options))
      end

      def notify_now
        new.notify_now
      end

      def notify_later
        new.notify_later
      end
    end

    def notify_now
    end

    def notify_later
    end
  end
end

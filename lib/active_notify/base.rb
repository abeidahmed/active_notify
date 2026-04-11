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

      def notify_later(...)
        new.notify_later(...)
      end

      def with(params)
        new(params)
      end
    end

    attr_reader :params

    def initialize(params = {})
      @params = params
    end

    def notify_now
      lines.each do |_name, config|
        config.constant.new(self).notify_now
      end
    end

    def notify_later(args = {})
      lines.each do |_name, config|
        config.constant.new(self).notify_later(args)
      end
    end
  end
end

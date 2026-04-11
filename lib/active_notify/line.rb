require "active_support/core_ext/module/delegation"

module ActiveNotify
  class Line
    delegate :params, to: :owner

    def initialize(owner)
      @owner = owner
    end

    def notify_now
      # Override in subclasses to handle this notification.
    end

    def notify_later(_args = {})
      # Override in subclasses to handle this notification.
    end

    private

    attr_reader :owner
  end
end

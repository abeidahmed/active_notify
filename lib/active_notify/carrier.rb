require "active_support/core_ext/module/delegation"

module ActiveNotify
  class Carrier
    attr_reader :notifier
    delegate :params, to: :notifier

    def initialize(notifier)
      @notifier = notifier
    end

    def deliver_now
      # Override in subclasses to handle this notification.
    end

    def deliver_later(*)
      # Override in subclasses to handle this notification.
    end
  end
end

require "active_support/core_ext/module/delegation"

module ActiveNotify
  class Delivery
    delegate :params, to: :notifier

    def initialize(notifier)
      @notifier = notifier
    end

    def notify_now
      # Override in subclasses to handle this notification.
    end

    def notify_later(_args = {})
      # Override in subclasses to handle this notification.
    end

    private

    attr_reader :notifier
  end
end

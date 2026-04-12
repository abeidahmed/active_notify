require "active_support/core_ext/module/delegation"

module ActiveNotify
  class Carrier
    attr_reader :carrier_name
    delegate :params, to: :notifier

    def initialize(notifier, carrier_name:)
      @notifier = notifier
      @carrier_name = carrier_name
    end

    def deliver_now
      # Override in subclasses to handle this delivery.
    end

    def deliver_later(*)
      # Override in subclasses to handle this delivery.
    end

    private

    attr_reader :notifier
  end
end

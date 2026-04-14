# frozen_string_literal: true

require "active_support/core_ext/class/attribute"
require_relative "carrier_descriptor"
require_relative "callbacks"

module ActiveNotify
  # = Active \Notify \Base
  #
  # Provides a base class for defining notifiers that dispatch a single
  # notification across multiple carriers (email, SMS, push, etc.) from a
  # single place.
  #
  # A notifier declares the carriers it delivers through using
  # {.deliver_via}[rdoc-ref:Base.deliver_via] and is invoked using
  # {.deliver_now}[rdoc-ref:Base.deliver_now] or
  # {.deliver_later}[rdoc-ref:Base.deliver_later]. Parameters that need to
  # reach every carrier can be passed with {.with}[rdoc-ref:Base.with].
  #
  # A minimal implementation could be:
  #
  #   class CommentNotifier < ActiveNotify::Base
  #     deliver_via :email
  #     deliver_via :sms
  #   end
  #
  #   CommentNotifier.with(user: user).deliver_later
  #
  # Each call to +deliver_via+ resolves a carrier class (by convention,
  # +CommentNotifier::Email+ and +CommentNotifier::Sms+) that inherits from
  # ActiveNotify::Carrier and handles the actual delivery. The carrier can
  # be overridden with the +:class_name+ option:
  #
  #   class CommentNotifier < ActiveNotify::Base
  #     deliver_via :email, class_name: "CustomEmailCarrier"
  #   end
  #
  # == Conditional delivery
  #
  # Each carrier can be conditionally skipped with +:if+ or +:unless+.
  # The condition may be a symbol (method name), a proc, or a literal value:
  #
  #   class CommentNotifier < ActiveNotify::Base
  #     deliver_via :email, if: :email_subscribed?
  #     deliver_via :sms,   unless: ->(notifier) { notifier.params[:silent] }
  #
  #     def email_subscribed?
  #       params[:user].email_subscribed?
  #     end
  #   end
  #
  # == Default arguments
  #
  # Any options other than +:class_name+, +:if+, and +:unless+ are passed
  # through to the carrier's +deliver_later+ method as default arguments.
  # Procs and symbols are evaluated against the notifier instance:
  #
  #   class CommentNotifier < ActiveNotify::Base
  #     deliver_via :email, queue: :urgent, wait: ->(notifier) { notifier.params[:delay] }
  #   end
  #
  # Subclasses inherit the carriers of their parent, and can add or
  # override carriers by calling +deliver_via+ again.
  class Base
    include Callbacks

    class_attribute :carriers, instance_writer: false, default: {}

    class << self
      # Registers a carrier that this notifier delivers through.
      #
      # The +carrier_name+ is a symbol that identifies the carrier and is
      # used to resolve the carrier class by convention (e.g. +:email+
      # resolves to +Email+ under the notifier's namespace). Pass
      # +:class_name+ to override the default resolution.
      #
      # The +:if+ and +:unless+ options are used to conditionally skip the
      # carrier; any remaining options are forwarded to the carrier's
      # +deliver_later+ method as default arguments.
      #
      #   class CommentNotifier < ActiveNotify::Base
      #     deliver_via :email
      #     deliver_via :sms, class_name: "TwilioCarrier", if: :phone_verified?
      #     deliver_via :push, queue: :notifications
      #   end
      def deliver_via(carrier_name, options = {})
        self.carriers = carriers.merge(carrier_name => CarrierDescriptor.new(carrier_name, self, options))
        define_carrier_callbacks(carrier_name)
      end

      # Delivers the notification synchronously through every registered
      # carrier. Equivalent to +new.deliver_now+.
      #
      #   CommentNotifier.deliver_now
      def deliver_now
        new.deliver_now
      end

      # Enqueues the notification for background delivery through every
      # registered carrier. Any arguments are forwarded to the carrier's
      # +deliver_later+ method and override per-carrier defaults declared
      # with {.deliver_via}[rdoc-ref:Base.deliver_via].
      #
      #   CommentNotifier.deliver_later
      #   CommentNotifier.deliver_later(wait: 5.minutes, queue: :low)
      def deliver_later(...)
        new.deliver_later(...)
      end

      # Builds a notifier instance with the given +params+ so that they
      # can be accessed from carriers and callbacks via +params+.
      #
      #   CommentNotifier.with(user: user, comment: comment).deliver_later
      def with(params)
        new(params)
      end
    end

    # The params passed to {.with}[rdoc-ref:Base.with] (or +new+). Available
    # to callbacks and carriers via the +params+ accessor.
    attr_reader :params

    # Initializes a new notifier with the given +params+. Normally you
    # will call {.with}[rdoc-ref:Base.with] rather than +new+ directly.
    def initialize(params = {})
      @params = params
    end

    # Delivers the notification synchronously through every registered
    # carrier, running +before_delivery+, +around_delivery+, and
    # +after_delivery+ callbacks as well as per-carrier callbacks.
    def deliver_now
      perform_deliveries do |instance|
        instance.deliver_now
      end
    end

    # Enqueues the notification for background delivery through every
    # registered carrier. +args+ are merged on top of each carrier's
    # default arguments declared with +deliver_via+ and passed to the
    # carrier's +deliver_later+ method.
    def deliver_later(args = {})
      perform_deliveries do |instance, descriptor|
        instance.deliver_later(descriptor.args(self).merge(args))
      end
    end

    private

    def perform_deliveries
      run_delivery_callbacks do
        carriers.each do |name, descriptor|
          if descriptor.deliver?(self)
            run_carrier_callbacks(name) do
              yield descriptor.constant.new(self, carrier_name: name), descriptor
            end
          end
        end
      end
    end
  end
end

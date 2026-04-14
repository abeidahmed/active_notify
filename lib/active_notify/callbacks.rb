require "active_support/callbacks"
require "active_support/concern"

module ActiveNotify
  # = Active \Notify \Callbacks
  #
  # Provides a callback mechanism around notification delivery, mixed in
  # automatically by ActiveNotify::Base. Callbacks can be registered to
  # wrap the full delivery (all carriers) or a single carrier at a time.
  #
  # Three kinds of callbacks are available: +before_delivery+,
  # +after_delivery+, and +around_delivery+. Each accepts one or more
  # method names, a block, or both, along with an optional +:on+ target
  # to scope the callback to a specific carrier.
  #
  #   class CommentNotifier < ActiveNotify::Base
  #     deliver_via :email
  #     deliver_via :sms
  #
  #     before_delivery :log_delivery
  #     after_delivery  :record_metrics
  #
  #     before_delivery :ensure_email_verified, on: :email
  #     around_delivery :with_timeout,          on: :sms
  #
  #     private
  #
  #     def log_delivery
  #       Rails.logger.info("Delivering #{self.class.name}")
  #     end
  #   end
  #
  # == Global vs per-carrier callbacks
  #
  # A callback without +:on+ runs once per delivery, wrapping the whole
  # set of carriers. A callback with +:on+ runs only when that specific
  # carrier is about to deliver. Per-carrier callbacks are skipped if the
  # carrier is skipped by its +:if+ or +:unless+ condition.
  #
  # == Skipping callbacks in subclasses
  #
  # Inherited callbacks can be removed with +skip_before_delivery+,
  # +skip_after_delivery+, and +skip_around_delivery+:
  #
  #   class QuietNotifier < CommentNotifier
  #     skip_before_delivery :log_delivery
  #     skip_before_delivery :ensure_email_verified, on: :email
  #   end
  module Callbacks
    extend ActiveSupport::Concern
    include ActiveSupport::Callbacks

    included do
      define_callbacks :delivery
    end

    class_methods do
      def define_carrier_callbacks(carrier_name) # :nodoc:
        define_callbacks carrier_name
      end

      # :method: before_delivery
      # :call-seq: before_delivery(*names, on: :delivery, **options, &block)
      #
      # Registers a callback to run before a delivery. Without +:on+ the
      # callback wraps the whole notification; with +:on+ it wraps a
      # single carrier.
      #
      #   before_delivery :log_delivery
      #   before_delivery :verify_phone, on: :sms
      #   before_delivery { |notifier| ... }

      # :method: after_delivery
      # :call-seq: after_delivery(*names, on: :delivery, **options, &block)
      #
      # Registers a callback to run after a delivery. See +before_delivery+.

      # :method: around_delivery
      # :call-seq: around_delivery(*names, on: :delivery, **options, &block)
      #
      # Registers a callback to wrap a delivery. The callback receives
      # the notifier and a block that performs the delivery; call +yield+
      # (or the block) to invoke it.

      # :method: skip_before_delivery
      # :call-seq: skip_before_delivery(*names, on: :delivery, **options)
      #
      # Removes a previously-registered +before_delivery+ callback,
      # typically in a subclass. Pass +:on+ to target a per-carrier
      # callback.

      # :method: skip_after_delivery
      # :call-seq: skip_after_delivery(*names, on: :delivery, **options)
      #
      # Removes a previously-registered +after_delivery+ callback.

      # :method: skip_around_delivery
      # :call-seq: skip_around_delivery(*names, on: :delivery, **options)
      #
      # Removes a previously-registered +around_delivery+ callback.

      %i[before after around].each do |kind|
        define_method "#{kind}_delivery" do |*names, on: :delivery, **options, &block|
          names.each do |name|
            set_callback on, kind, name, options
          end

          set_callback on, kind, block, options if block
        end

        define_method "skip_#{kind}_delivery" do |*names, on: :delivery, **options|
          names.each do |name|
            skip_callback on, kind, name, options
          end
        end
      end
    end

    private

    def run_delivery_callbacks(&)
      run_callbacks(:delivery, &)
    end

    def run_carrier_callbacks(carrier_name, &)
      run_callbacks(carrier_name, &)
    end
  end
end

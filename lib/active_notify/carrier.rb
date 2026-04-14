require "active_support/core_ext/module/delegation"

module ActiveNotify
  # = Active \Notify \Carrier
  #
  # Base class for carriers - the adapters that actually deliver a
  # notification through a particular channel (email, SMS, push, etc.).
  # A carrier is resolved and instantiated by ActiveNotify::Base for
  # each +deliver_via+ entry, then either +deliver_now+ or +deliver_later+
  # is invoked on it.
  #
  # Carriers are resolved by convention: +deliver_via :email+ on
  # +CommentNotifier+ looks for +CommentNotifier::Email+. Override with
  # the +:class_name+ option if the carrier lives elsewhere.
  #
  # A minimal carrier subclasses +ActiveNotify::Carrier+ and implements
  # +deliver_now+ and/or +deliver_later+:
  #
  #   class CommentNotifier < ActiveNotify::Base
  #     deliver_via :email
  #
  #     class Email < ActiveNotify::Carrier
  #       def deliver_now
  #         message.deliver_now
  #       end
  #
  #       def deliver_later(options = {})
  #         message.deliver_later(options)
  #       end
  #
  #       private
  #
  #       def message
  #         CommentMailer.with(params).new_comment
  #       end
  #     end
  #   end
  #
  # == Accessing params
  #
  # The params passed via ActiveNotify::Base.with are available on the
  # carrier as +params+ (delegated to the underlying notifier), so
  # carriers can read the same data the notifier saw:
  #
  #   CommentNotifier.with(user: user, comment: comment).deliver_later
  #
  #   class CommentNotifier::Sms < ActiveNotify::Carrier
  #     def deliver_now
  #       TwilioClient.send_sms(
  #         to: params[:user].phone,
  #         body: "New comment: #{params[:comment].body}"
  #       )
  #     end
  #   end
  #
  # == +carrier_name+
  #
  # Each carrier instance knows which +deliver_via+ entry it was
  # instantiated for via +carrier_name+. This is useful when the same
  # carrier class is reused for multiple channels:
  #
  #   class CommentNotifier < ActiveNotify::Base
  #     deliver_via :email, class_name: "GenericMailCarrier"
  #     deliver_via :digest, class_name: "GenericMailCarrier"
  #   end
  #
  #   class GenericMailCarrier < ActiveNotify::Carrier
  #     def deliver_now
  #       Mailer.public_send(carrier_name, **params).deliver_now
  #     end
  #   end
  #
  # The default +deliver_now+ and +deliver_later+ implementations are
  # no-ops, so a carrier that only supports one delivery mode does not
  # need to implement the other.
  class Carrier
    # The symbolic name this carrier was registered under via
    # ActiveNotify::Base.deliver_via (e.g. +:email+, +:sms+).
    attr_reader :carrier_name

    delegate :params, to: :notifier

    def initialize(notifier, carrier_name:)
      @notifier = notifier
      @carrier_name = carrier_name
    end

    # Delivers the notification synchronously. Override in subclasses.
    # The default implementation is a no-op.
    def deliver_now
    end

    # Enqueues the notification for background delivery. Receives the
    # merged default arguments from +deliver_via+ and any arguments
    # passed to ActiveNotify::Base.deliver_later. Override in subclasses.
    # The default implementation is a no-op.
    def deliver_later(*)
    end

    private

    attr_reader :notifier
  end
end

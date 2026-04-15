# Carriers

A carrier is the adapter that actually delivers a notification through a single channel - email, SMS, push, Slack, Action Cable, and so on. A notifier fans out to one or more carriers; each carrier decides what "deliver" means for its channel.

Every carrier inherits from `ActiveNotify::Carrier` and implements `deliver_now`, `deliver_later`, or both. Both methods default to no-ops on the base class, so a carrier that only supports one delivery mode does not need to define the other.

## Defining a carrier

Declare the channels on the notifier with `deliver_via`, then define a carrier class for each one:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :email
  deliver_via :sms

  private

  class Email < ActiveNotify::Carrier
    def deliver_now
      CommentMailer.with(params).new_comment.deliver_now
    end

    def deliver_later(options = {})
      CommentMailer.with(params).new_comment.deliver_later(options)
    end
  end

  class Sms < ActiveNotify::Carrier
    def deliver_now
      TwilioClient.send_sms(to: params[:user].phone, body: params[:comment].body)
    end
    alias_method :deliver_later, :deliver_now
  end
end
```

By convention, `deliver_via :email` resolves to a `CommentNotifier::Email` constant, and `:sms` to `CommentNotifier::Sms` (Rails `String#classify` rules apply - `:action_cable` resolves to `ActionCable`).

## Accessing params

The hash passed to `ActiveNotify::Base.with` is available on every carrier as `params`:

```ruby
CommentNotifier.with(user: user, comment: comment).deliver_later
```

```ruby
class CommentNotifier::Sms < ActiveNotify::Carrier
  def deliver_now
    TwilioClient.send_sms(
      to: params[:user].phone,
      body: "New comment: #{params[:comment].body}"
    )
  end
end
```

`params` is delegated from the underlying notifier, so the carrier sees exactly what the notifier saw - no copying required.

## `carrier_name`

Each carrier instance knows which `deliver_via` entry it was built for through `carrier_name`. This is useful when one carrier class handles several channels:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :new_comment, class_name: "GenericMailCarrier"
  deliver_via :digest,      class_name: "GenericMailCarrier"
end

class GenericMailCarrier < ActiveNotify::Carrier
  def deliver_now
    # `carrier_name` can either be `new_comment` or `digest`.
    CommentMailer.with(params).public_send(carrier_name).deliver_now
  end
end
```

## Pointing at an existing class

By default, the carrier class must live under the notifier's namespace. Use `:class_name` to point at a class somewhere else - typically when a carrier is shared between several notifiers:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :email, class_name: "GenericMailCarrier"
  deliver_via :sms,   class_name: "Notifications::TwilioCarrier"
end
```

`:class_name` takes a string (resolved later through `constantize`), so the referenced class does not need to be loaded at the time `deliver_via` is called.

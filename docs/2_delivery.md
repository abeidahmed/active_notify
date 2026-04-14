# Delivery

A notifier exposes two entry points: `deliver_now` runs every carrier synchronously in the caller's thread, and `deliver_later` enqueues each carrier's delivery for background execution. Either one can be called directly on the class or on an instance built with `with`.

## Passing params

Use `with` to attach data that every carrier (and every callback) can read as `params`:

```ruby
CommentNotifier.with(user: user, comment: comment).deliver_later
```

`with` returns a notifier instance, so it chains cleanly with either delivery method:

```ruby
CommentNotifier.with(user: user, comment: comment).deliver_now
```

Calling `deliver_now` or `deliver_later` directly on the class is equivalent to `new.deliver_{now,later}` - useful when a notifier doesn't need any params.

## Synchronous vs asynchronous

`deliver_now` invokes each carrier's `deliver_now`. Use it when delivery must happen inline - for example, in a test or when the caller already runs inside a job.

`deliver_later` invokes each carrier's `deliver_later` and forwards any arguments through:

```ruby
CommentNotifier.with(user: user).deliver_later(wait: 5.minutes, queue: :low)
```

What the arguments mean is up to the carrier. A carrier that wraps Action Mailer, for instance, can pass them straight through to `deliver_later`:

```ruby
class CommentNotifier::Email < ActiveNotify::Carrier
  def deliver_later(options = {})
    CommentMailer.with(params).new_comment.deliver_later(options)
  end
end
```

## Default arguments

Options passed to `deliver_via` (other than `:class_name`, `:if`, and `:unless`) become default arguments for that carrier's `deliver_later`:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :email, queue: :urgent, wait: 2.minutes
  deliver_via :sms,   queue: :critical
end
```

Procs and symbols are evaluated against the notifier instance, so defaults can depend on `params`:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :email, queue: -> { queue }
  deliver_via :sms,   wait: 2.minutes

  def queue
    params[:user].professional? ? :urgent : :slow
  end
end
```

Arguments passed at the call site are merged on top of the per-carrier defaults, so call-site values win:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :email, queue: :urgent, wait: 2.minutes
end

# Carrier sees { queue: :low, wait: 2.minutes }
CommentNotifier.deliver_later(queue: :low)
```

`deliver_now` ignores these arguments - they are only meaningful for background delivery.

## Conditional delivery

A carrier can opt out of a particular delivery with `:if` or `:unless`. The condition runs once per delivery against the notifier instance:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :email, if: :email_subscribed?
  deliver_via :sms,   unless: -> { params[:silent] }

  private

  def email_subscribed?
    params[:user].email_subscribed?
  end
end
```

The condition may be:

- a **symbol** - sent as a method call to the notifier (`:email_subscribed?`)
- a **proc** - one-arity procs receive the notifier; zero-arity procs are evaluated with `instance_exec`
- a **literal value** - any truthy/falsy value works, which is occasionally useful for feature flags

When a carrier is skipped, its per-carrier callbacks are skipped along with it. Global callbacks (without `:on`) still run, since they wrap the whole notification. See [callbacks.md](3_callbacks.md) for the callback side of this interaction.

# Callbacks

Callbacks let you run code around a delivery - to log, persist a record of the notification, open a tracing span, or short-circuit with a raised exception. Active Notify exposes three kinds: `before_delivery`, `after_delivery`, and `around_delivery`. Each one can wrap the whole notification or a single carrier.

## Registering a callback

Declare callbacks in the notifier. They accept a method name, a block, or both:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :email
  deliver_via :sms

  before_delivery :log_delivery
  after_delivery  :record_notification

  around_delivery do |_notifier, block|
    Rails.logger.tagged("CommentNotifier", &block)
  end

  private

  def log_delivery
    Rails.logger.info("Delivering #{self.class.name} for #{params[:user].id}")
  end

  def record_notification
    Notification.create!(recipient: params[:user], comment: params[:comment])
  end
end
```

Around callbacks receive the notifier and a block - invoke the block (or call `yield`) to perform the delivery. Skipping the block short-circuits the whole notification.

## Global vs per-carrier callbacks

A callback declared without `:on` wraps the entire delivery - it runs once regardless of how many carriers the notifier has:

```ruby
before_delivery :log_delivery        # runs once per notification
```

Pass `:on` to scope the callback to a single carrier. It only runs when that carrier is about to deliver:

```ruby
before_delivery :verify_phone,  on: :sms
after_delivery  :record_open,   on: :email
around_delivery :with_timeout,  on: :push
```

Per-carrier callbacks are skipped along with the carrier when the carrier's `:if` / `:unless` condition returns false. Global callbacks (no `:on`) still run in that case, since they wrap the whole notification. See [delivery.md](2_delivery.md) for conditional delivery.

## Order of execution

For a notifier with `:email` and `:sms` carriers and the following callbacks:

```ruby
before_delivery :log_delivery
after_delivery  :record_notification

before_delivery :verify_email, on: :email
after_delivery  :record_sms,   on: :sms
```

the sequence is:

```
log_delivery
  verify_email
    <email deliver>
    <sms deliver>
  record_sms
record_notification
```

Global `before` / `after` callbacks wrap the whole set. Per-carrier callbacks wrap their own carrier's delivery only.

## Skipping inherited callbacks

Subclasses inherit every callback declared on the parent. Use `skip_before_delivery`, `skip_after_delivery`, or `skip_around_delivery` to remove one - pass `:on` when removing a per-carrier callback:

```ruby
class QuietNotifier < CommentNotifier
  skip_before_delivery :log_delivery
  skip_before_delivery :verify_email, on: :email
end
```

The skip matches by callback name and scope, so removing `:verify_email` without `:on` would not affect the per-carrier registration - the `:on` must match the original declaration.

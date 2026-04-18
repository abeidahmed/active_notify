# Testing

Active Notify ships a minitest helper that captures deliveries instead of dispatching them, so you can assert on what a notifier sent without invoking carriers or hitting external services.

## Setup

Require the testing module from your `test_helper.rb` and include `ActiveNotify::TestHelper` in any test case that exercises a notifier:

```ruby
# test/test_helper.rb
require "active_notify/testing"
```

```ruby
# test/notifiers/comment_notifier_test.rb
class CommentNotifierTest < ActiveSupport::TestCase
  include ActiveNotify::TestHelper

  # ...
end
```

## Asserting on deliveries

Both `deliver_now` and `deliver_later` are intercepted while the helper is active. Use the count assertions to check how many notifications a block produced:

```ruby
test "delivers a comment notification" do
  assert_notify_deliveries 1 do
    CommentNotifier.with(user: user).deliver_now
  end
end

test "enqueues a digest" do
  assert_enqueued_notify_deliveries 1 do
    DigestNotifier.with(user: user).deliver_later
  end
end
```

Counts include every carrier on the notifier - a notifier with `:email` and `:sms` carriers calling `deliver_now` once produces two recorded deliveries.

## Inspecting deliveries

For deeper assertions on what was recorded, capture the deliveries and inspect them directly:

```ruby
test "passes params through" do
  deliveries = capture_notify_deliveries do
    CommentNotifier.with(user: user, comment: comment).deliver_now
  end

  assert_equal CommentNotifier, deliveries.first[:notifier_class]
  assert_equal :email, deliveries.first[:carrier_name]
  assert_equal user, deliveries.first[:params][:user]
end
```

Each entry is a hash with `:notifier_class`, `:carrier_name`, `:method_name` (`:deliver_now` or `:deliver_later`), `:params`, and `:args`.

## Reference

See [test/testing/minitest_test.rb](../test/testing/minitest_test.rb) for the full set of assertions and their failure-message behavior.

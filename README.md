# Active Notify

Active Notify is a Rails framework for delivering notifications across multiple channels - email, SMS, push, Slack,
Action Cable, you name it. You declare which carriers a notifier uses, and Active Notify fans out the delivery, runs
callbacks, and handles per-carrier configuration.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem "active_notify"
```

Then run:

```sh
bundle install
```

## Usage

Declare a notifier, the carriers it delivers through, and the carrier classes themselves. Each `deliver_via` resolves a carrier class by convention - `:email` looks for `CommentNotifier::Email`, `:sms` for `CommentNotifier::Sms` - and each carrier inherits from `ActiveNotify::Carrier` and implements `deliver_now` and/or `deliver_later`:

```ruby
class CommentNotifier < ActiveNotify::Base
  deliver_via :email, wait: 2.minutes
  deliver_via :sms

  after_delivery :record_notification

  private

  def record_notification
    Notification.create!(recipient: params[:user], comment: params[:comment])
  end

  class Email < ActiveNotify::Carrier
    def deliver_later(options = {})
      CommentMailer.with(params).new_comment.deliver_later(options)
    end
  end

  class Sms < ActiveNotify::Carrier
    def deliver_later
      TwilioClient.send_sms(to: params[:user].phone, body: params[:comment].body)
    end
  end
end
```

Deliver the notification, passing any data the carriers need through `with`:

```ruby
CommentNotifier.with(user: user, comment: comment).deliver_later
```

The hash passed to `with` is available to every carrier (and every callback) as `params`.

## Guides

- [carriers.md](docs/1_carriers.md) - write a carrier class for a delivery channel
- [delivery.md](docs/2_delivery.md) - sync vs async delivery, default args, conditional delivery
- [callbacks.md](docs/3_callbacks.md) - run code before, after, or around a delivery

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abeidahmed/active_notify. This project is
intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
[code of conduct](https://github.com/abeidahmed/active_notify/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveNotify project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/abeidahmed/active_notify/blob/main/CODE_OF_CONDUCT.md).

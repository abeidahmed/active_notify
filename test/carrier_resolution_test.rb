require "test_helper"

class CarrierResolutionTest < ActiveSupport::TestCase
  class MockNotifier < ActiveNotify::Base
    deliver_via :email
    deliver_via :sms, class_name: "TestCarrier"

    private

    class Email < TestCarrier; end
  end

  setup do
    TestHistory.reset
  end

  test "resolves the carrier from a constant nested under the notifier" do
    MockNotifier.deliver_now

    assert_equal [:email, :sms], TestHistory.carriers
  end

  test "class_name: takes precedence over convention" do
    MockNotifier.deliver_now

    assert_equal :sms, TestHistory.entries.last[:carrier]
  end

  class MockNotifierWithMissingCarrier < ActiveNotify::Base
    deliver_via :email
  end

  test "raises when the carrier constant cannot be resolved" do
    assert_raises(NameError) do
      MockNotifierWithMissingCarrier.deliver_now
    end
  end
end

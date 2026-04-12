require "test_helper"

class DefaultArgsTest < ActiveSupport::TestCase
  class MockNotifier < ActiveNotify::Base
    deliver_via :email, class_name: "TestCarrier", wait: 5, priority: :urgent
    deliver_via :sms, class_name: "TestCarrier", priority: :default
  end

  setup do
    TestHistory.reset
  end

  test "#deliver_later has default args" do
    MockNotifier.deliver_later

    assert_equal({ wait: 5, priority: :urgent }, TestHistory.entries.first[:args])
    assert_equal({ priority: :default }, TestHistory.entries.last[:args])
  end

  test "#deliver_later runtime args override default args" do
    params = { wait: 7, priority: :urgent }
    MockNotifier.deliver_later(params)

    assert_equal params, TestHistory.entries.first[:args]
    assert_equal params, TestHistory.entries.last[:args]
  end

  class MockNotifierWithEvaluableArgs < ActiveNotify::Base
    deliver_via :email, class_name: "TestCarrier", wait: -> { computed_wait }, priority: :urgent
    deliver_via :sms, class_name: "TestCarrier", wait: ->(notifier) { notifier.computed_wait * 2 }
    deliver_via :discord, class_name: "TestCarrier", wait: 5, priority: -> { :slow }

    def computed_wait
      10
    end
  end

  test "#deliver_later evaluates args" do
    MockNotifierWithEvaluableArgs.deliver_later

    assert_equal({ wait: 10, priority: :urgent }, TestHistory.entries.first[:args])
    assert_equal({ wait: 20 }, TestHistory.entries[1][:args])
    assert_equal({ wait: 5, priority: :slow }, TestHistory.entries.last[:args])
  end
end

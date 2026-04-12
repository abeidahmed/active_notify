$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "active_notify"

require "active_support/test_case"
require "minitest/autorun"

class TestHistory
  def self.entries
    @entries ||= []
  end

  def self.carriers
    entries.map { |e| e[:carrier] }
  end

  def self.reset
    @entries = []
  end
end

class TestCarrier < ActiveNotify::Carrier
  def deliver_now
    TestHistory.entries << { carrier: carrier_name, method: :deliver_now, params: }
  end

  def deliver_later(args = {})
    TestHistory.entries << { carrier: carrier_name, method: :deliver_later, params:, args: }
  end
end

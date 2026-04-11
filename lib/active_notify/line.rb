require "active_support/core_ext/module/delegation"

module ActiveNotify
  class Line
    delegate :params, to: :owner

    def initialize(owner)
      @owner = owner
    end

    private

    attr_reader :owner
  end
end

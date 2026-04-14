# frozen_string_literal: true

require_relative "lib/active_notify/version"

Gem::Specification.new do |spec|
  spec.name = "active_notify"
  spec.version = ActiveNotify::VERSION
  spec.authors = ["abeidahmed"]
  spec.email = ["abeidahmed92@gmail.com"]

  spec.summary = "Rails framework for delivering notifications across multiple channels."
  spec.description = "Rails framework for delivering notifications across multiple channels."
  spec.homepage = "https://github.com/abeidahmed/active_notify"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6.1"
end

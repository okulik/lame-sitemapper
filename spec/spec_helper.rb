# frozen_string_literal: true

require "bundler/setup"
require "lame_sitemapper"

require "yaml"
require "ostruct"
require "typhoeus"

require "core"
require "url_helper"
require "page"
require "cli"

RSpec.configure do |config|
  config.before(:each) do
    Typhoeus::Expectation.clear
  end
end

RSpec::Matchers.define :exit_with_code do |exp_code|
  actual = nil

  match do |block|
    begin
      block.call
    rescue SystemExit => e
      actual = e.status
    end
    actual and actual == exp_code
  end

  failure_message do |block|
    "expected block to call exit(#{exp_code}) but exit" +
      (actual.nil? ? " not called" : "(#{actual}) was called")
  end

  failure_message_when_negated do |block|
    "expected block not to call exit(#{exp_code})"
  end

  description do
    "expect block to call exit(#{exp_code})"
  end
end

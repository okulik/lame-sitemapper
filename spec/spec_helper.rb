require "yaml"
require "ostruct"
require "spec_helper"
require "typhoeus"
require_relative "../config/patch"
require_relative "../config/init_settings"
require_relative "../config/init_logger"
require_relative "../cli"
require_relative "../core"
require_relative "../url_helper"
require_relative "../page"

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.before :each do
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
  failure_message_for_should do |block|
    "expected block to call exit(#{exp_code}) but exit" +
      (actual.nil? ? " not called" : "(#{actual}) was called")
  end
  failure_message_for_should_not do |block|
    "expected block not to call exit(#{exp_code})"
  end
  description do
    "expect block to call exit(#{exp_code})"
  end
end

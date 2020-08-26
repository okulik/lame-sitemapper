# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/hash/conversions"

module Sitemapper
  SETTINGS = begin
    settings_file = File.join(__dir__, "settings.yml")
    env = $PROGRAM_NAME =~ /rspec$/i ? "test" : "production"
    YAML::load(IO.read(settings_file))[env].deep_symbolize_keys
  end
end

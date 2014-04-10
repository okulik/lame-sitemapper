require "yaml"

module SiteMapper
  env = $PROGRAM_NAME =~ /rspec$/i ? "test" : "production"
  SETTINGS = YAML::load(IO.read(File.join(File.dirname(__FILE__), "settings.yml")))[env].symbolize
end

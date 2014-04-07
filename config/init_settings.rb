require 'yaml'

module SiteMapper
  SETTINGS = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'settings.yml'))).symbolize
end

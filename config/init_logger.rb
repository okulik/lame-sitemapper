require "logger"
require "time"

module SiteMapper
  logger = Logger.new($PROGRAM_NAME =~ /rspec$/i ? "log/crawl-test.log" : "log/crawl.log", 10, 5242880)
  logger.level = SETTINGS[:log_level].to_i
  logger.datetime_format = "%Y-%m-%d %H:%M:%S "
  LOGGER = logger
end

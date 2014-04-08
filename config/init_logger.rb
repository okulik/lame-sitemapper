require 'logger'
require 'time'

module SiteMapper
  logger = Logger.new($PROGRAM_NAME =~ /rspec$/i ? 'crawl-test.log' : 'crawl.log', 10, 1024000)
  logger.level = SETTINGS[:log_level].to_i
  logger.datetime_format = '%Y-%m-%d %H:%M:%S '
  LOGGER = logger
end

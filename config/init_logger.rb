require 'logger'
require 'time'

module SiteMapper
  logger = Logger.new($stdout)
  logger.level = SETTINGS[:log_level].to_i
  logger.datetime_format = '%Y-%m-%d %H:%M:%S '
  LOGGER = logger
end

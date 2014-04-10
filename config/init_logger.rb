require "logger"
require "time"

module SiteMapper
  logger = Logger.new(File.join("log", SETTINGS[:log][:file_name]), SETTINGS[:log][:file_count], SETTINGS[:log][:file_size])
  logger.level = SETTINGS[:log_level].to_i
  logger.datetime_format = "%Y-%m-%d %H:%M:%S "
  logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')} #{Thread.current[:name]}] #{severity[0]} -- : #{msg}\n"
  end
  LOGGER = logger
end

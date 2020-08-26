# frozen_string_literal: true

require "time"
require "logger"

module Sitemapper
  LOGGER = begin
    log_file = SETTINGS[:log][:file_name]
    Logger.new(log_file, SETTINGS[:log][:file_count], SETTINGS[:log][:file_size]).tap do |logger|
      logger.level = SETTINGS[:log_level].to_i
      logger.datetime_format = "%Y-%m-%d %H:%M:%S "
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')} #{Thread.current[:name]}] #{severity[0]} -- : #{msg}\n"
      end
    end
  end
end

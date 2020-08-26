# frozen_string_literal: true

require "optparse"
require "ostruct"

require_relative "config/init_settings"
require_relative "config/init_logger"
require_relative "sitemapper/version"
require_relative "core"
require_relative "url_helper"
require_relative "report_generator"

module Sitemapper
  class Cli
    attr_reader :opt_parser

    def initialize(out = nil, args = [], run_file = File.basename(__FILE__))
      @out = out
      @args = args
      
      @options = OpenStruct.new
      @options.use_robots = Sitemapper::SETTINGS[:use_robots]
      @options.max_page_depth = Sitemapper::SETTINGS[:max_page_depth]
      @options.log_level = Sitemapper::SETTINGS[:log_level].to_i
      @options.report_type = Sitemapper::SETTINGS[:report_type]
      @options.frequency_type = Sitemapper::SETTINGS[:sitemap_frequency_type]
      @options.scraper_threads = Sitemapper::SETTINGS[:scraper_threads].to_i

      Thread.current[:name] = "**"

      @opt_parser = OptionParser.new do |opts|
        opts.banner = "Generate sitemap.xml for a given url."
        opts.separator ""
        opts.separator "Usage: ruby #{run_file} [options] <uri>"
        opts.separator "url needs to be in the form of e.g. http://www.nisdom.com"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("--[no-]robots", "Run with robots.txt") do |r|
          @options.use_robots = r
        end

        opts.on("-l", "--log-level LEVEL", "Set log level from 0 to 4, 0 is most verbose (default 1)") do |level|
          if level.to_i < 0 || level.to_i > 4
            @out.puts opts if @out
            exit
          end
          LOGGER.level = level.to_i
        end

        opts.on("-d", "--depth DEPTH", "Set maximum page traversal depth from 1 to 10 (default 10)") do |depth|
          if depth.to_i < 1 || depth.to_i > 10
            @out.puts opts if @out
            exit
          end
          @options.max_page_depth = depth.to_i
        end

        report_types = [:text, :sitemap, :html, :graph, :test_yml]
        opts.on("-r", "--report-type TYPE", report_types, "Set report type #{report_types.map {|f| '\'' + f.to_s + '\''}.join(", ")} (defalut 'text')") do |type|
          @options.report_type = type
        end

        change_frequency = [:none, :always, :hourly, :daily, :weekly, :monthly, :yearly, :never]
        opts.on("--change-frequency FREQ", change_frequency, "Set sitemap's page change frequency #{change_frequency.map {|f| '\'' + f.to_s + '\''}.join(", ")} (default 'daily')") do |freq|
          @options.frequency_type = freq
        end

        opts.on("-t", "--scraper-threads NUM", "Set number of scraper threads from 1 to 10 (default 1)") do |num|
          if num.to_i < 1 || num.to_i > 10
            @out.puts opts if @out
            exit
          end
          @options.scraper_threads = num.to_i
        end

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-h", "--help", "Display this screen") do
          @out.puts opts if @out
          exit
        end

        opts.on_tail("-v", "--version", "Show version") do
          @out.puts Version::STRING if @out
          exit
        end
      end
    end

    def run
      @opt_parser.parse! @args
      if @args.empty?
        @out.puts @opt_parser if @out
        exit
      end

      start_url = @args.shift
      normalized_host = UrlHelper::get_normalized_host(start_url)
      normalized_start_url = UrlHelper::get_normalized_url(normalized_host, start_url)
      if normalized_host.nil? || normalized_start_url.nil?
        @out.puts @opt_parser if @out
        exit
      end

      LOGGER.info "starting with #{normalized_start_url}, options #{@options.inspect}"
      
      start_time = Time.now
      root, normalized_start_url = Core.new(@out, @options).start(normalized_host, normalized_start_url)
      return unless root

      LOGGER.info "found #{root.count} pages in #{Time.now - start_time}s"

      @out.puts ReportGenerator.new(@options, normalized_start_url).send("to_#{@options.report_type}", root) if @out
    rescue OptionParser::InvalidArgument, OptionParser::InvalidOption, OptionParser::MissingArgument =>e
      @out.puts e if @out
      @out.puts @opt_parser if @out
      exit
    end
  end
end

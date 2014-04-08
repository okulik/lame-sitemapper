require 'optparse'
require 'ostruct'

require_relative 'config/patch'
require_relative 'config/init_settings'
require_relative 'config/init_logger'
require_relative 'version'
require_relative 'crawler'
require_relative 'url_helper'
require_relative 'report_generator'

module SiteMapper
  class Cli
    attr_reader :opt_parser

    def initialize out = nil, args=[], run_file=File.basename(__FILE__)
      @out = out
      @args = args
      
      @options = OpenStruct.new
      @options.ignore_robots = SETTINGS[:ignore_robots]
      @options.max_page_depth = SETTINGS[:max_page_depth]
      @options.log_level = SETTINGS[:log_level]
      @options.report_type = SETTINGS[:report_type]
      @options.frequency_type = SETTINGS[:frequency_type]

      @opt_parser = OptionParser.new do |opts|
        opts.banner = 'Generate sitemap.xml for a given uri.'
        opts.separator ''
        opts.separator "Usage: ruby #{run_file} [options] <uri>"
        opts.separator 'uri needs to be in the form of e.g. http://digitalocean.com:80/'
        opts.separator ''
        opts.separator 'Specific options:'

        opts.on('-i', '--ignore-robots', 'Do not follow advices from robots.txt') do
          @options.ignore_robots = true
        end

        opts.on('-l', '--log-level LEVEL', 'Set log level ranging from most verbose 0 (DEBUG) to 4 (FATAL)') do |level|
          if level.to_i < 0 || level.to_i > 4
            @out.puts opts if @out
            exit
          end
          @options.log_level = LOGGER.level = level.to_i
        end

        opts.on('-d', '--depth DEPTH', 'Sets maximum page traversal depth, should be greater than 0') do |depth|
          if depth.to_i < 1
            @out.puts opts if @out
            exit
          end
          @options.max_page_depth = depth.to_i
        end

        report_types = [:text, :sitemap, :html]
        opts.on('-r', '--report-type TYPE', report_types, "Select report type (#{report_types.join(',')})") do |type|
          @options.report_type = type
        end

        change_frequency = [:none, :always, :hourly, :daily, :weekly, :monthly, :yearly, :never]
        opts.on('--change-frequency FREQ', change_frequency, "Select pages change frequency for sitemap report (#{change_frequency.join(',')})") do |freq|
          @options.frequency_type = freq
        end

        opts.separator ''
        opts.separator 'Common options:'

        opts.on_tail('-h', '--help', 'Display this screen') do
          @out.puts opts if @out
          exit
        end

        opts.on_tail('-v', '--version', 'Show version') do
          @out.puts Version::STRING if @out
          exit
        end
      end
    end

    def run
      begin
        @opt_parser.parse! @args
        if @args.empty?
          @out.puts @opt_parser if @out
          exit
        end

        host = @args.shift
        normalized_host = UrlHelper::get_normalized_host(host)

        unless normalized_host
          @out.puts @opt_parser if @out
          exit
        end

        tree = Crawler.new(@out, @options).start(normalized_host)
        return unless tree

        LOGGER.info "found #{tree.count} pages"

        @out.puts ReportGenerator.new(@options).send("to_#{@options.report_type}", tree) if @out
      rescue OptionParser::InvalidArgument, OptionParser::InvalidOption, OptionParser::MissingArgument =>e
        @out.puts e if @out
        @out.puts @opt_parser if @out
        exit
      end
    end
  end
end

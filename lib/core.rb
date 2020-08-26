# frozen_string_literal: true

require "typhoeus"
require "webrobots"
require "addressable/uri"

require_relative "scraper"
require_relative "page"
require_relative "url_helper"
require_relative "web_helper"

module Sitemapper
  class Core
    def initialize(out, opts)
      @out = out
      @opts = opts
    end

    def start(host, start_url)
      if @opts.use_robots
        @robots = WebRobots.new(SETTINGS[:web_settings][:useragent], {
          crawl_delay: :sleep,
          :http_get => lambda do |url|
            response = WebHelper.get_http_response(url)
            return unless response
            return response.body.force_encoding("UTF-8")
          end
        })

        if error = @robots.error(host)
          msg = "unable to fetch robots.txt"
          LOGGER.fatal msg
          $stderr.puts msg
          return [nil, start_url]
        end
      end

      # check if our host redirects to somewhere else, if it does, change start_url to redirect url
      response = WebHelper.get_http_response(start_url, :head)
      unless response
        msg = "unable to fetch starting url"
        LOGGER.fatal msg
        $stderr.puts msg

        return [nil, start_url]
      end

      if response.redirect_count.to_i > 0
        host = UrlHelper::get_normalized_host(response.effective_url) 
        start_url = UrlHelper::get_normalized_url(host, response.effective_url)
      end

      urls_queue = Queue.new
      pages_queue = Queue.new
      seen_urls = {}
      threads = []
      root = nil

      Thread.abort_on_exception = true
      (1..@opts.scraper_threads.to_i).each_with_index do |index|
        threads << Thread.new { Scraper.new(seen_urls, urls_queue, pages_queue, index, @opts, @robots).run }
      end

      urls_queue.push(host: host, url: start_url, depth: 0, parent: root)

      loop do
        msg = pages_queue.pop
        if msg[:page]
          if LOGGER.info?
            if msg[:page].scraped?
              details = ": a(#{msg[:page].anchors.count}), img(#{msg[:page].images.count}), link(#{msg[:page].links.count}), script(#{msg[:page].scripts.count})"
            else
              details = ": #{msg[:page].format_codes}"
            end
            LOGGER.info "#{UrlHelper.log_prefix(msg[:depth])} created at #{msg[:page].path}#{details}"
          end

          msg[:page].anchors.each do |anchor|
            urls_queue.push(host: host, url: anchor, depth: msg[:depth] + 1, parent: msg[:page])
          end

          if msg[:parent].nil?
            root = msg[:page]
          else
            msg[:parent].sub_pages << msg[:page]
          end
        end

        if urls_queue.empty? && pages_queue.empty?
          until urls_queue.num_waiting == threads.size
            Thread.pass
          end
          if pages_queue.empty?
            threads.size.times { urls_queue << nil }
            break
          end
        end
      end

      threads.each { |thread| thread.join }

      [root, start_url]
    end
  end
end

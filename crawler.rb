require "typhoeus"
require "digest/murmurhash"
require "webrobots"
require "addressable/uri"

require_relative "page"
require_relative "url_helper"

module SiteMapper
  class Crawler
    attr_reader :seen_pages

    EXTRACT_TAGS = [
        ["//a/@href", "anchors"],
        ["//img/@src", "images"],
        ["//link/@href", "links"],
        ["//script/@src", "scripts"]
      ]
    LOG_INDENT = " " * 2

    def initialize(out, opts)
      @out = out
      @opts = opts
      @seen_pages = {}
    end

    def get_http_response(url, method=:get)
      response = Typhoeus.send(method, url.to_s, SETTINGS[:web_settings])
      return nil unless response
      if response.timed_out?
        LOGGER.warn "resource at #{url} not accessible" 
        return nil
      end
      return { body: response.body, code: response.code, effective_url: response.effective_url, redirect_count: response.redirect_count, headers: response.headers }
    end

    def start(host, start_url)
      unless @opts.skip_robots
        @robots = WebRobots.new(SETTINGS[:web_settings][:useragent], {
          crawl_delay: :sleep,
          :http_get => lambda do |url|
            r = get_http_response(url)
            return nil unless r && r[:code] >= 200 && r[:code] < 300 && r[:body]
            return r[:body].force_encoding("UTF-8")
          end
        })
        if error = @robots.error(host)
          LOGGER.fatal "unable to retrieve robots.txt, exiting (error #{error.inspect})"
          exit 1
        end
      end

      # check if our host redirects to somewhere else, if it does, change start_url to redirect url
      r = get_http_response(start_url, :head)
      unless r
        LOGGER.fatal "unable to fetch starting url, exiting"
        exit 2
      end
      start_url = UrlHelper.get_normalized_url(host, r[:effective_url]) if r && r[:redirect_count].to_i > 0

      return [crawl(host, start_url), start_url]
    end

    private

    def crawl(host, url, depth=0)
      page = create_page(host, url, depth)
      return nil unless page

      if LOGGER.info?
        if page.scraped?
          details = ": a(#{page.anchors.count}), img(#{page.images.count}), link(#{page.links.count}), script(#{page.scripts.count})"
        else
          details = ": #{page.format_codes}"
        end
        LOGGER.info "#{prefix(depth)} created at #{page.path}#{details}"
      end

      page.anchors.each do |a|
        sub_page = crawl(host, a, depth + 1)
        page.sub_pages << sub_page if sub_page
      end

      return page
    end

    def create_page(host, url, depth)
      normalized_url = UrlHelper.get_normalized_url(host, url)
      return nil unless normalized_url
      
      return nil if already_seen?(normalized_url, depth)
      page = Page.new(normalized_url)
      seen_pages[Digest::MurmurHash64B.hexdigest(normalized_url.to_s)] = page
      return page unless should_crawl?(host, page, depth)

      r = get_http_response(normalized_url)
      
      if r.nil? || r[:body].nil?
        LOGGER.error "failed to get HTML from url #{normalized_url}"
        return nil
      end

      if r[:headers] && r[:headers]["Content-Type"] !~ /text\/html/
        LOGGER.debug "#{prefix(depth)} stopping, #{page.path} is not html"
        page.no_html = true
        return page
      end

      # if we had redirect, verify url once more
      if r[:redirect_count].to_i > 0
        normalized_url = UrlHelper.get_normalized_url(host, r[:effective_url])
        return page unless normalized_url

        page.path = normalized_url # modify path to match redirect
        return nil if already_seen?(normalized_url, depth)
        seen_pages[Digest::MurmurHash64B.hexdigest(normalized_url.to_s)] = page
        return page unless should_crawl?(host, page, depth)
      end

      doc = Nokogiri::HTML(r[:body])
      unless doc
        LOGGER.error "failed to parse document from url #{normalized_url}"
        return page
      end

      EXTRACT_TAGS.each do |expression, collection|
        doc.xpath(expression).each { |attr| page.send(collection) << attr.value }
        page.instance_variable_set("@#{collection}", page.send(collection).reject(&:empty?).uniq)
      end

      return page
    end

    def already_seen?(url, depth)
      if seen_pages[Digest::MurmurHash64B.hexdigest(url.to_s)]
        LOGGER.debug "#{prefix(depth)} skipping #{url}, already seen"
        return true
      end

      return false
    end

    def should_crawl?(host, page, depth)
      # check if url is on the same domain as host
      unless UrlHelper.is_url_same_domain?(host, page.path)
        LOGGER.debug "#{prefix(depth)} stopping, #{page.path} is ext host"
        page.external_domain = true
        return false
      end

      # check if url is allowed with robots.txt
      if @robots && @robots.disallowed?(page.path.to_s)
        LOGGER.debug "#{prefix(depth)} stopping, #{page.path} is robots.txt disallowed"
        page.robots_forbidden = true
        return false
      end

      # check if max traversal depth has been reached
      if depth >= @opts[:max_page_depth].to_i
        LOGGER.debug "#{prefix(depth)} stopping, max traversal depth reached"
        page.depth_reached = true
        return false
      end

      return true
    end

    def prefix(depth)
      "#{LOG_INDENT * depth}(#{depth})"
    end
  end
end

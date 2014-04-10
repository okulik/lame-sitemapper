require "typhoeus"
require "digest/murmurhash"
require "webrobots"
require "addressable/uri"

require_relative "page"
require_relative "url_helper"

module SiteMapper
  class Crawler
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
      @seen_urls = {}
    end

    def get_http_response(url, method=:get)
      response = Typhoeus.send(method, url.to_s, SETTINGS[:web_settings])
      return nil unless response

      if response.timed_out?
        LOGGER.warn "resource at #{url} timed-out" 
        return nil
      end

      unless response.success?
        LOGGER.warn "resource at #{url} returned error code #{response.code}" 
        return nil
      end

      if response.body.nil?
        LOGGER.warn "resource at #{url} returned empty body" 
        return nil
      end

      return response
    end

    def start(host, start_url)
      unless @opts.skip_robots
        @robots = WebRobots.new(SETTINGS[:web_settings][:useragent], {
          crawl_delay: :sleep,
          :http_get => lambda do |url|
            response = get_http_response(url)
            return nil unless response
            return response.body.force_encoding("UTF-8")
          end
        })
        if error = @robots.error(host)
          LOGGER.fatal "unable to retrieve robots.txt, exiting (error #{error.inspect})"
          exit 1
        end
      end

      # check if our host redirects to somewhere else, if it does, change start_url to redirect url
      response = get_http_response(start_url, :head)
      unless response
        LOGGER.fatal "unable to fetch starting url, exiting"
        exit 2
      end
      start_url = UrlHelper.get_normalized_url(host, response.effective_url) if response.redirect_count.to_i > 0

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
        LOGGER.info "#{log_prefix(depth)} created at #{page.path}#{details}"
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
      
      return nil if is_url_already_seen?(normalized_url, depth)
      set_already_seen_url(normalized_url)
      page = Page.new(normalized_url)
      return page unless should_crawl_page?(host, page, depth)

      response = get_http_response(normalized_url)
      unless response
        LOGGER.error "failed to get resource for #{normalized_url}"
        page.not_accessible = true
        return page
      end

      if response.headers && response.headers["Content-Type"] !~ /text\/html/
        LOGGER.debug "#{log_prefix(depth)} stopping, #{page.path} is not html"
        page.no_html = true
        return page
      end

      # if we had redirect, verify url once more
      if response.redirect_count.to_i > 0
        normalized_url = UrlHelper.get_normalized_url(host, response.effective_url)
        return page unless normalized_url

        page.path = normalized_url # modify path to match redirect
        return nil if is_url_already_seen?(normalized_url, depth)
        set_already_seen_url(normalized_url)
        return page unless should_crawl_page?(host, page, depth)
      end

      doc = Nokogiri::HTML(response.body)
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

    def is_url_already_seen?(url, depth)
      if @seen_urls[Digest::MurmurHash64B.hexdigest(url.to_s)]
        LOGGER.debug "#{log_prefix(depth)} skipping #{url}, already seen"
        return true
      end

      return false
    end

    def set_already_seen_url(url)
      @seen_urls[Digest::MurmurHash64B.hexdigest(url.to_s)] = true
    end

    def should_crawl_page?(host, page, depth)
      # check if url is on the same domain as host
      unless UrlHelper.is_url_same_domain?(host, page.path)
        LOGGER.debug "#{log_prefix(depth)} stopping, #{page.path} is ext host"
        page.external_domain = true
        return false
      end

      # check if url is allowed with robots.txt
      if @robots && @robots.disallowed?(page.path.to_s)
        LOGGER.debug "#{log_prefix(depth)} stopping, #{page.path} is robots.txt disallowed"
        page.robots_forbidden = true
        return false
      end

      # check if max traversal depth has been reached
      if depth >= @opts[:max_page_depth].to_i
        LOGGER.debug "#{log_prefix(depth)} stopping, max traversal depth reached"
        page.depth_reached = true
        return false
      end

      return true
    end

    def log_prefix(depth)
      "#{LOG_INDENT * depth}(#{depth})"
    end
  end
end

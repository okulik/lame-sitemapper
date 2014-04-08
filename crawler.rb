require "typhoeus"
require "digest/murmurhash"
require "webrobots"
require "addressable/uri"
require "uri"

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

    def get_http_response(uri, method=:get)
      response = Typhoeus.send(method, uri.to_s, SETTINGS[:web_settings])
      return nil unless response
      return { body: response.body, code: response.code, effective_url: response.effective_url, redirect_count: response.redirect_count }
    end

    def start(host)
      unless @opts.skip_robots
        @robots = WebRobots.new(SETTINGS[:web_settings][:useragent], {
          crawl_delay: :sleep,
          :http_get => lambda do |uri|
            r = get_http_response(uri)
            return nil unless r && r[:code] >= 200 && r[:code] < 300 && r[:body]
            return r[:body].force_encoding("UTF-8")
          end
        })
        if error = @robots.error(host)
          LOGGER.fatal "unable to retrieve robots.txt, error #{error.inspect}"
          exit 1
        end
      end

      # check if our host redirects to somewhere else, if it does, change host to redirect url
      r = get_http_response(host, :head)
      host = UrlHelper.get_normalized_host(r[:effective_url]) if r && r[:redirect_count].to_i > 0

      return [crawl(host, host), host]
    end

    private

    def crawl(host, uri, depth=0)
      page = create_page(host, uri, depth)
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

    def create_page(host, uri, depth)
      normalized_uri = UrlHelper.get_normalized_uri(host, uri)
      return nil unless normalized_uri
      
      return nil if already_seen?(normalized_uri, depth)
      page = Page.new(normalized_uri)
      seen_pages[Digest::MurmurHash64B.hexdigest(normalized_uri.to_s)] = page
      return page unless should_crawl?(host, page, depth)

      r = get_http_response(normalized_uri)
      if r.nil? || r[:body].nil?
        LOGGER.error "failed to get HTML from url #{normalized_uri}"
        return nil
      end

      # if we had redirect, verify url once more
      if r[:redirect_count].to_i > 0
        normalized_uri = UrlHelper.get_normalized_uri(host, r[:effective_url])
        return page unless normalized_uri

        page.path = normalized_uri # modify path to match redirect
        return nil if already_seen?(normalized_uri, depth)
        seen_pages[Digest::MurmurHash64B.hexdigest(normalized_uri.to_s)] = page
        return page unless should_crawl?(host, page, depth)
      end

      doc = Nokogiri::HTML(r[:body])
      unless doc
        LOGGER.error "failed to parse document from url #{normalized_uri}"
        return page
      end

      EXTRACT_TAGS.each do |expression, collection|
        doc.xpath(expression).each { |attr| page.send(collection) << attr.value }
        page.instance_variable_set("@#{collection}", page.send(collection).reject(&:empty?).uniq)
      end

      return page
    end

    def already_seen?(uri, depth)
      if seen_pages[Digest::MurmurHash64B.hexdigest(uri.to_s)]
        LOGGER.debug "#{prefix(depth)} skipping #{uri}, already seen"
        return true
      end

      return false
    end

    def should_crawl?(host, page, depth)
      page.non_scraped_code = 0

      # check if uri is on the same domain as host
      unless UrlHelper.is_uri_same_domain?(host, page.path)
        LOGGER.debug "#{prefix(depth)} skipping #{page.path}, ext host"
        page.non_scraped_code |= Page::NON_SCRAPED_DOMAIN
        return false
      end

      # check if uri is allowed with robots.txt
      if @robots && @robots.disallowed?(page.path.to_s)
        LOGGER.debug "#{prefix(depth)} skipping #{page.path}, robots.txt disallowed"
        page.non_scraped_code |= Page::NON_SCRAPED_ROBOTS
        return false
      end

      # check if max traversal depth has been reached
      if depth >= @opts[:max_page_depth].to_i
        LOGGER.debug "#{prefix(depth)} max traversal depth reached"
        page.non_scraped_code |= Page::NON_SCRAPED_DEPTH
        return false
      end

      return true
    end

    def prefix(depth)
      "#{LOG_INDENT * depth}(#{depth})"
    end
  end
end

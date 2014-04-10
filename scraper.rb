require "digest/murmurhash"

require_relative "page"
require_relative "url_helper"
require_relative "web_helper"

module SiteMapper
  class Scraper
    EXTRACT_TAGS = [
      ["//a/@href", "anchors"],
      ["//img/@src", "images"],
      ["//link/@href", "links"],
      ["//script/@src", "scripts"]
    ]

    def initialize(seen_urls, urls_queue, pages_queue, index, opts, robots)
      @seen_urls = seen_urls
      @urls_queue = urls_queue
      @pages_queue = pages_queue
      @index = index
      @opts = opts
      @robots = robots
    end

    def run
      Thread.current[:name] = "%02d" % @index
      LOGGER.debug "running scraper #{@index}"
      loop do
        msg = @urls_queue.pop
        unless msg
          LOGGER.debug "scraper #{@index} received finish message"
          break
        end

        page = create_page(msg)

        @pages_queue.push(page: page, url: msg[:url], depth: msg[:depth], parent: msg[:parent])
      end
    end

    private

    def create_page(args)
      normalized_url = UrlHelper.get_normalized_url(args[:host], args[:url])
      unless normalized_url
        LOGGER.error "failed to normalize url #{args[:url]}"
        return nil
      end
      
      return nil if is_url_already_seen?(normalized_url, args[:depth])
      set_already_seen_url(normalized_url)
      page = Page.new(normalized_url)
      return page unless should_crawl_page?(args[:host], page, args[:depth])

      response = WebHelper.get_http_response(normalized_url)
      unless response
        LOGGER.error "failed to get resource for #{normalized_url}"
        page.not_accessible = true
        return page
      end

      if response.headers && response.headers["Content-Type"] !~ /text\/html/
        LOGGER.debug "#{UrlHelper.log_prefix(args[:depth])} stopping, #{page.path} is not html"
        page.no_html = true
        return page
      end

      # if we had redirect, verify url once more
      if response.redirect_count.to_i > 0
        normalized_url = UrlHelper.get_normalized_url(args[:host], response.effective_url)
        unless normalized_url
          LOGGER.error "failed to normalize url #{response.effective_url}"
          return page 
        end

        page.path = normalized_url # modify path to match redirect
        return nil if is_url_already_seen?(normalized_url, args[:depth])
        set_already_seen_url(normalized_url)
        return page unless should_crawl_page?(args[:host], page, args[:depth])
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

      LOGGER.debug "#{UrlHelper.log_prefix(args[:depth])} scraped page at #{normalized_url}"

      return page
    end

    def is_url_already_seen?(url, depth)
      if @seen_urls[Digest::MurmurHash64B.hexdigest(url.omit(:scheme).to_s)]
        LOGGER.debug "#{UrlHelper.log_prefix(depth)} skipping #{url}, already seen"
        return true
      end

      return false
    end

    def set_already_seen_url(url)
      @seen_urls[Digest::MurmurHash64B.hexdigest(url.omit(:scheme).to_s)] = true
    end

    def should_crawl_page?(host, page, depth)
      # check if url is on the same domain as host
      unless UrlHelper.is_url_same_domain?(host, page.path)
        LOGGER.debug "#{UrlHelper.log_prefix(depth)} stopping, #{page.path} is ext host"
        page.external_domain = true
        return false
      end

      # check if url is allowed with robots.txt
      if @robots && @robots.disallowed?(page.path.to_s)
        LOGGER.debug "#{UrlHelper.log_prefix(depth)} stopping, #{page.path} is robots.txt disallowed"
        page.robots_forbidden = true
        return false
      end

      # check if max traversal depth has been reached
      if depth >= @opts[:max_page_depth].to_i
        LOGGER.debug "#{UrlHelper.log_prefix(depth)} stopping, max traversal depth reached"
        page.depth_reached = true
        return false
      end

      return true
    end
  end
end

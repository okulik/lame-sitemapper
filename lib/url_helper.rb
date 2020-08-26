# frozen_string_literal: true

require "addressable/uri"
require "public_suffix"

module LameSitemapper
  class UrlHelper
    SUPPORTED_SCHEMAS = %w(http https)
    LOG_INDENT = " " * 2

    def self.get_normalized_host(host_string)
      host_url = Addressable::URI.heuristic_parse(host_string, scheme: "http")
      
      return unless SUPPORTED_SCHEMAS.include?(host_url.scheme)
      return unless host_url.host
      return if host_url.host =~ /\s/
      return unless PublicSuffix.valid?(host_url.host)
      host_url.omit!(:path, :query, :fragment)

      Addressable::URI.encode(host_url, ::Addressable::URI).normalize
    rescue Addressable::URI::InvalidURIError, TypeError
      nil
    end

    def self.get_normalized_url(host_url, resource_url)
      host_url = Addressable::URI.parse(host_url)
      resource_url = Addressable::URI.parse(resource_url)

      m = {}
      m[:scheme] = host_url.scheme unless resource_url.scheme
      unless resource_url.host
        m[:host] = host_url.host
        m[:port] = host_url.port
      end
      resource_url.merge!(m) unless m.empty?
      return unless SUPPORTED_SCHEMAS.include?(resource_url.scheme)
      return unless PublicSuffix.valid?(resource_url.host)
      resource_url.omit!(:fragment)
      resource_url.query = resource_url.query.split("&").map(&:strip).sort.join("&") unless resource_url.query.nil? || resource_url.query.empty?

      Addressable::URI.encode(resource_url, ::Addressable::URI).normalize
    rescue Addressable::URI::InvalidURIError, TypeError
      nil
    end

    def self.is_url_same_domain?(host_url, resource_url)
      host_url = Addressable::URI.parse(host_url)
      resource_url = Addressable::URI.parse(resource_url)
      host_url.host == resource_url.host
    end

    def self.log_prefix(depth)
      "#{LOG_INDENT * depth}(#{depth})"
    end
  end
end

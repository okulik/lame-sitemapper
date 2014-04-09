require "addressable/uri"
require "public_suffix"

module SiteMapper
  class UrlHelper
    SUPPORTED_SCHEMAS = %w(http https)

    def self.get_normalized_host(host_string)
      host_url = Addressable::URI.heuristic_parse(host_string, scheme: "http")
      
      return nil unless SUPPORTED_SCHEMAS.include?(host_url.scheme)
      return nil unless host_url.host
      return nil if host_url.host =~ /\s/
      return nil unless PublicSuffix.valid?(host_url.host)
      host_url.omit!(:path, :query, :fragment)

      return Addressable::URI.encode(host_url, ::Addressable::URI).normalize
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
      return nil unless SUPPORTED_SCHEMAS.include?(resource_url.scheme)
      return nil unless PublicSuffix.valid?(resource_url.host)
      resource_url.omit!(:fragment)
      resource_url.query = resource_url.query.split("&").map(&:strip).sort.join("&") unless resource_url.query.nil? || resource_url.query.empty?

      return Addressable::URI.encode(resource_url, ::Addressable::URI).normalize
    rescue Addressable::URI::InvalidURIError, TypeError
      nil
    end

    def self.is_url_same_domain?(host_url, resource_url)
      host_url = Addressable::URI.parse(host_url)
      resource_url = Addressable::URI.parse(resource_url)
      host_url.host == resource_url.host
    end
  end
end

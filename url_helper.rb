require "addressable/uri"
require "uri"

module SiteMapper
  class UrlHelper
    def self.get_normalized_host host
      URI.parse(host)
      uri = Addressable::URI.parse(host)
      return nil unless uri
      uri = uri.normalize
      return nil unless %w(http https).include?(uri.scheme)
      return nil unless (uri.path.empty? || uri.path == "/") && uri.query.nil?
      return nil unless uri.to_s =~ URI::DEFAULT_PARSER.regexp[:ABS_URI]
      uri
    rescue URI::BadURIError, URI::InvalidURIError
      nil
    end

    def self.get_normalized_uri host, uri
      # convert to Addressable::URI
      host = Addressable::URI.parse(host) unless host.is_a?(Addressable::URI)

      # expand urls to a full path
      url_string = uri.to_s
      if url_string.start_with?("//")
        url_string = "#{host.scheme}:#{url_string}" 
      elsif url_string.start_with?("/")
        url_string = host.to_s + url_string[1..-1]
      elsif url_string !~ /^http(s)?\:\/\//
        url_string = "#{host}#{url_string}"
      end

      # verify final path (will throw if invalid)
      URI.parse(url_string)

      # convert string back to Addressable::URI
      uri = Addressable::URI.parse(url_string).normalize
      
      # remove fragments and reorder query parameters
      uri.fragment = nil
      uri.query = uri.query.split("&").map(&:strip).sort.join("&") unless uri.query.nil? || uri.query.empty?

      return uri
    rescue URI::BadURIError, URI::InvalidURIError
      nil
    end

    def self.is_uri_same_domain? host, uri
      host.host == uri.host
    end
  end
end

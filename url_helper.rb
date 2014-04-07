require 'addressable/uri'
require 'uri'

module SiteMapper
  class UrlHelper
    def self.get_normalized_host host
      URI.parse(host)
      uri = Addressable::URI.parse(host)
      return nil unless uri
      uri = uri.normalize
      return nil unless %w(http https).include?(uri.scheme)
      return nil unless (uri.path.empty? || uri.path == '/') && uri.query.nil?
      return nil unless uri.to_s =~ URI::DEFAULT_PARSER.regexp[:ABS_URI]
      uri
    rescue URI::BadURIError, URI::InvalidURIError
      nil
    end

    def self.get_normalized_uri host, uri
      host = Addressable::URI.parse(host) unless host.is_a?(Addressable::URI)
      url = uri.to_s
      if url.start_with?('//')
        url = "#{host.scheme}:#{url}" 
      elsif url.start_with?('/')
        url = host.to_s + url[1..-1]
      elsif url !~ /^http(s)?\:\/\//
        url = "#{host}#{url}"
      end
      URI.parse(url)
      Addressable::URI.parse(url).normalize
    rescue URI::BadURIError, URI::InvalidURIError
      nil
    end

    def self.is_uri_same_domain? host, uri
      host.host == uri.host
    end
  end
end

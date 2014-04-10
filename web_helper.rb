require 'typhoeus'

module SiteMapper
  class WebHelper
    def self.get_http_response(url, method=:get)
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
  end
end

# frozen_string_literal: true

require "typhoeus"

module LameSitemapper
  class WebHelper
    def self.get_http_response(url, method=:get)
      response = Typhoeus.send(method, url.to_s, SETTINGS[:web_settings])
      return if response.nil?

      if response.timed_out?
        LOGGER.warn "resource at #{url} timed-out" 
        return
      end

      unless response.success?
        LOGGER.warn "resource at #{url} returned error code #{response.code}" 
        return
      end

      if response.body.nil?
        LOGGER.warn "resource at #{url} returned empty body" 
        return
      end

      response
    end
  end
end

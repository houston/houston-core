require "faraday"

module Faraday
  class UnexpectedResponse < RuntimeError
    attr_reader :response

    def initialize(response)
      @response = response
      super "Unexpected response (#{response.status}) from #{response.env[:url].host}#{response.env[:url].path}"
    end
  end

  module Expect
    def expect!(*status_codes)
      return if status_codes.include?(status)
      fail UnexpectedResponse.new(self)
    end
    alias :must_be! :expect!
  end
end

Faraday::Response.send :include, Faraday::Expect

require "faraday"

module Houston
  module HTTP
    class Error < RuntimeError
      attr_reader :env
      
      def initialize(env, message=nil)
        @env = env
        super message || default_message(env)
      end
      
      def default_message(env)
        "#{env[:status]} from #{env[:url].host}#{env[:url].path}"
      end
    end
    
    class ClientError < Error; end
    class ServerError < Error; end
    class UnrecognizedResponse < Error; end
    
    CLIENT_ERRORS = {
      400 => :BadRequest,
      401 => :Unauthorized,
      403 => :Forbidden,
      406 => :NotAcceptable,
      410 => :Gone,
      422 => :UnprocessableEntity }.freeze
    
    SERVER_ERRORS = {
      500 => :ServerError,
      502 => :BadGateway,
      503 => :ServiceUnavailable,
      504 => :GatewayTimeout }.freeze
    
    ERRORS = CLIENT_ERRORS.merge(SERVER_ERRORS).freeze
    
    CLIENT_ERRORS.each do |code, error|
      const_set error, Class.new(Houston::HTTP::ClientError)
    end
    
    SERVER_ERRORS.each do |code, error|
      const_set error, Class.new(Houston::HTTP::ServerError)
    end
    
    class RaiseErrors < Faraday::Response::Middleware
      def on_complete(env)
        binding.pry
        case env[:status]
        when 404
          raise Faraday::Error::ResourceNotFound, response_values(env)
        when 407
          # mimic the behavior that we get with proxy requests with HTTPS
          raise Faraday::Error::ConnectionFailed, %{407 "Proxy Authentication Required "}
        when 400..599
          error = ERRORS.fetch(status, :UnrecognizedResponse)
          exception = Houston::HTTP.const_get error
          raise exception.new(env)
        end
      end
      
      def response_values(env)
        { status: env[:status], headers: env[:response_headers], body: env[:body] }
      end
    end
    
  end
end
  
require "faraday"
require "json"

module Houston
  module Beltic
    class Client
      attr_reader :config

      def initialize(config)
        raise ConfigurationError, "Beltic api_key is not set" unless config.configured?
        @config = config
      end

      def post(path, body)
        request(:post, path, body)
      end

      def get(path, params = {})
        request(:get, path, nil, params)
      end

      def delete(path)
        request(:delete, path)
      end

      private

      def request(method, path, body = nil, params = {})
        response = connection.public_send(method) do |req|
          req.url(path)
          req.params.update(params) if params && !params.empty?
          if body
            req.headers["Content-Type"] = "application/json"
            req.body = body.is_a?(String) ? body : JSON.generate(body)
          end
        end

        handle_response(response)
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        raise TransportError.new(e.message, raw: e)
      end

      def handle_response(response)
        body = parse_body(response.body)

        case response.status
        when 200..299
          body
        else
          # Beltic's error envelope: { "error": { "code", "message", "details", "request_id" } }
          # Older endpoints occasionally still flatten to top-level keys; tolerate both.
          err = body.is_a?(Hash) ? (body["error"] || body) : {}
          code    = err["code"] || err["error_code"]
          message = err["message"] || err["error_message"] || response.body
          raise Houston::Beltic.error_for(
            code:        code,
            message:     message || "Beltic API error",
            http_status: response.status,
            raw:         body,
          )
        end
      end

      def parse_body(raw)
        return {} if raw.nil? || raw.empty?
        JSON.parse(raw)
      rescue JSON::ParserError
        raw
      end

      def connection
        @connection ||= Faraday.new(url: config.base_url) do |f|
          f.headers["X-Api-Key"]    = config.api_key
          f.headers["User-Agent"]   = "houston-core (beltic-integration)"
          f.headers["Accept"]       = "application/json"
          f.options.timeout         = config.request_timeout
          f.options.open_timeout    = config.open_timeout
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end

require "houston/beltic/errors"
require "houston/beltic/client"
require "houston/beltic/issuer"
require "houston/beltic/verifier"
require "houston/beltic/webhook_verifier"

module Houston
  module Beltic
    class Configuration
      attr_accessor :api_key, :base_url, :webhook_secret,
                    :org_credential_id, :org_subject_id,
                    :issuer_did, :jwks_url, :status_list_url,
                    :request_timeout, :open_timeout

      def initialize
        @base_url        = "https://api.beltic.com/v1"
        @issuer_did      = "did:web:beltic.com"
        @request_timeout = 10
        @open_timeout    = 5
      end

      def configured?
        !api_key.nil? && !api_key.empty?
      end

      # Derive well-known URLs from base_url unless explicitly overridden.
      # Lets BELTIC_BASE_URL=http://localhost:8080/v1 just work without setting
      # jwks_url / status_list_url separately.
      def jwks_url
        @jwks_url ||= well_known("jwks.json")
      end

      def status_list_url
        @status_list_url ||= well_known("status-lists/v1")
      end

      private

      def well_known(suffix)
        origin = base_url.to_s.sub(%r{/v\d+/?\z}, "")
        "#{origin}/.well-known/#{suffix}"
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield(config)
      end

      def client
        @client ||= Client.new(config)
      end

      def issuer
        @issuer ||= Issuer.new(client)
      end

      def verifier
        @verifier ||= Verifier.new(config)
      end

      def reset!
        @client = @issuer = @verifier = nil
      end
    end
  end
end

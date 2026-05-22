module Houston
  module Beltic
    class Error < StandardError
      attr_reader :code, :http_status, :raw

      def initialize(message, code: nil, http_status: nil, raw: nil)
        super(message)
        @code        = code
        @http_status = http_status
        @raw         = raw
      end
    end

    class ConfigurationError < Error; end
    class TransportError < Error; end

    class APIError < Error; end
    class AuthenticationError < APIError; end
    class PermissionError < APIError; end
    class NotFoundError < APIError; end
    class RateLimitError < APIError; end
    class ServerError < APIError; end

    class SelfAttestationIncompleteError < APIError; end
    class KYBRequiredError < APIError; end
    class DelegationMissingError < APIError; end
    class SchemaValidationError < APIError; end

    class VerificationError < Error; end
    class RevokedError < VerificationError; end
    class ExpiredError < VerificationError; end
    class PolicyDeniedError < VerificationError; end
    class WebhookSignatureError < Error; end

    # Maps Beltic's `error.code` strings (see Beltic platform: packages/schemas/src/credentials/shared/responses.ts)
    # to typed exception classes.
    ERROR_CODE_MAP = {
      "self_attestation_incomplete" => SelfAttestationIncompleteError,
      "validation_failed"           => SchemaValidationError,
      "malformed_request"           => SchemaValidationError,
      "missing_required_field"      => SchemaValidationError,
      "unauthorized"                => AuthenticationError,
      "forbidden"                   => PermissionError,
      "not_found"                   => NotFoundError,
      "conflict"                    => APIError,
      "idempotency_key_conflict"    => APIError,
      "unprocessable_entity"        => APIError,
      "internal_error"              => ServerError,
      "upstream_error"              => ServerError,
      "kms_signing_failed"          => ServerError,
      "database_error"              => ServerError,
      # Domain-level codes Houston may emit client-side or that Beltic returns in some flows
      "kyb_required"                => KYBRequiredError,
      "delegated_by_required"       => DelegationMissingError,
    }.freeze

    def self.error_for(code:, message:, http_status:, raw: nil)
      klass = ERROR_CODE_MAP[code] || begin
        case http_status
        when 401      then AuthenticationError
        when 403      then PermissionError
        when 404      then NotFoundError
        when 422      then SchemaValidationError
        when 429      then RateLimitError
        when 500..599 then ServerError
        else               APIError
        end
      end
      klass.new(message, code: code, http_status: http_status, raw: raw)
    end
  end
end

require "openssl"

module Houston
  module Beltic
    # Verifies the HMAC-SHA256 signature on incoming Beltic webhook events.
    #
    # Beltic uses the Stripe-pattern signature format (see Beltic platform:
    # apps/api/credentials/src/operations/audit/streams/hmac-sign.ts):
    #
    #   Beltic-Signature: sha256=<hex digest>
    #   Beltic-Timestamp: <unix seconds>
    #
    # Signed payload is `"#{timestamp}.#{raw_body}"`. This binds the signature
    # to a specific moment in time, preventing replay attacks. We reject any
    # event whose timestamp differs from `Time.now` by more than `tolerance`
    # seconds (default 300, matching Beltic's recommendation).
    class WebhookVerifier
      SIGNATURE_HEADER = "Beltic-Signature".freeze
      TIMESTAMP_HEADER = "Beltic-Timestamp".freeze

      DEFAULT_TOLERANCE = 300 # seconds

      def initialize(secret, tolerance: DEFAULT_TOLERANCE)
        raise ConfigurationError, "Beltic webhook_secret is not set" if secret.nil? || secret.empty?
        @secret    = secret
        @tolerance = tolerance
      end

      # Returns true if signature + timestamp are valid; false otherwise.
      def valid?(raw_body, signature_header, timestamp_header)
        verify!(raw_body, signature_header, timestamp_header)
        true
      rescue WebhookSignatureError
        false
      end

      def verify!(raw_body, signature_header, timestamp_header)
        ts = parse_timestamp!(timestamp_header)
        check_freshness!(ts)
        provided = parse_signature!(signature_header)
        expected = sign(ts, raw_body)
        unless secure_compare(expected, provided)
          raise WebhookSignatureError, "Beltic-Signature does not match expected HMAC"
        end
        true
      end

      private

      def parse_timestamp!(header)
        raise WebhookSignatureError, "Beltic-Timestamp header missing"   if header.nil? || header.empty?
        raise WebhookSignatureError, "Beltic-Timestamp is not numeric"   unless header.to_s.match?(/\A\d+\z/)
        header.to_i
      end

      def check_freshness!(ts)
        delta = (Time.now.to_i - ts).abs
        return if delta <= @tolerance
        raise WebhookSignatureError, "Beltic-Timestamp #{ts} is outside the #{@tolerance}s tolerance (delta=#{delta}s)"
      end

      def parse_signature!(header)
        raise WebhookSignatureError, "Beltic-Signature header missing" if header.nil? || header.empty?
        unless header.start_with?("sha256=")
          raise WebhookSignatureError, "Beltic-Signature must use sha256= prefix (got #{header.split('=').first})"
        end
        hex = header.sub(/\Asha256=/, "")
        unless hex.match?(/\A[0-9a-f]+\z/i)
          raise WebhookSignatureError, "Beltic-Signature hex digest malformed"
        end
        hex.downcase
      end

      def sign(ts, body)
        OpenSSL::HMAC.hexdigest("SHA256", @secret, "#{ts}.#{body}")
      end

      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize
        l = a.unpack("C#{a.bytesize}")
        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res.zero?
      end
    end
  end
end

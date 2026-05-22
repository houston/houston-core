require "jwt"
require "faraday"
require "json"
require "base64"
require "zlib"
require "stringio"

module Houston
  module Beltic
    # Verifies a Beltic-issued JWT-VC.
    #
    # Two paths:
    #
    #   - Local (`verify`): sub-ms after warm cache. Pulls JWKS once from
    #     /.well-known/jwks.json, the Status List 2021 bitstring from
    #     /.well-known/status-lists/v1, verifies the JWT signature against the
    #     matching key, checks revocation against the bitstring, and evaluates
    #     the permission policy against the supplied transaction context. Use
    #     in the hot purchase path.
    #
    #   - Remote (`verify_remote!`): POST /v1/credentials/:id/verify on Beltic,
    #     producing an audit-trail event. Use for compliance-sensitive ops.
    #
    # Result object:
    #
    #   r = verifier.verify(jwt, resource_type: "wallet", action: "checkout",
    #                            transaction_amount: 9900, transaction_currency: "USD")
    #   r.valid?    # => true / false
    #   r.reason    # => :ok | :expired | :revoked | :policy_denied | :bad_signature | ...
    #   r.payload   # => parsed JWT payload (claims) when signature was good
    #
    class Verifier
      attr_reader :config

      Result = Struct.new(:valid?, :reason, :payload, :detail, keyword_init: true) do
        def ok?;          reason == :ok end
        def to_h;         { valid: valid?, reason: reason, detail: detail } end
      end

      def initialize(config)
        @config = config
        @jwks_cache = nil
        @jwks_fetched_at = nil
        @jwks_max_age = 600 # seconds; respect Cache-Control when present
        @status_list_cache = nil
        @status_list_fetched_at = nil
        @status_list_max_age = 60
      end

      # Local verification. ctx contains the transaction details to evaluate
      # against the credential's permission conditions, e.g.:
      #   { resource_type: "wallet", action: "checkout",
      #     transaction_amount: 5000, transaction_currency: "USD" }
      def verify(jwt, ctx = {})
        header, payload = decode_unverified(jwt)
        return Result.new(valid?: false, reason: :malformed, detail: "could not decode JWT") if header.nil?

        kid = header["kid"]
        jwk = find_key(kid)
        return Result.new(valid?: false, reason: :unknown_kid, detail: "no key for kid=#{kid}") unless jwk

        verified_payload = verify_signature!(jwt, jwk)
        return Result.new(valid?: false, reason: :bad_signature) unless verified_payload

        if expired?(verified_payload)
          return Result.new(valid?: false, reason: :expired, payload: verified_payload)
        end

        if revoked?(verified_payload)
          return Result.new(valid?: false, reason: :revoked, payload: verified_payload)
        end

        policy = evaluate_policy(verified_payload, ctx)
        unless policy[:ok]
          return Result.new(valid?: false, reason: :policy_denied, payload: verified_payload, detail: policy[:detail])
        end

        Result.new(valid?: true, reason: :ok, payload: verified_payload)
      end

      # Server-side verification with audit trail.
      def verify_remote!(credential_id, ctx = {})
        Houston::Beltic.client.post("/credentials/#{credential_id}/verify", ctx)
      end

      def invalidate_jwks!
        @jwks_cache = nil
      end

      def invalidate_status_list!
        @status_list_cache = nil
      end

      private

      def decode_unverified(jwt)
        header, payload, _sig = jwt.to_s.split(".")
        return [nil, nil] if header.nil? || payload.nil?
        [JSON.parse(b64u_decode(header)), JSON.parse(b64u_decode(payload))]
      rescue JSON::ParserError, ArgumentError
        [nil, nil]
      end

      def b64u_decode(str)
        # JWT uses base64url without padding.
        padding = "=" * ((4 - str.length % 4) % 4)
        Base64.urlsafe_decode64(str + padding)
      end

      def verify_signature!(jwt, jwk)
        key = ::JWT::JWK.import(jwk).verify_key
        decoded, _ = ::JWT.decode(jwt, key, true, algorithm: jwk["alg"] || "ES256")
        decoded
      rescue ::JWT::DecodeError, ::JWT::VerificationError
        nil
      end

      def find_key(kid)
        load_jwks!
        (@jwks_cache || []).find { |k| k["kid"] == kid }
      end

      def load_jwks!
        return @jwks_cache if @jwks_cache && fresh?(@jwks_fetched_at, @jwks_max_age)

        response = Faraday.get(config.jwks_url)
        raise VerificationError, "JWKS fetch failed: #{response.status}" unless response.success?
        body = JSON.parse(response.body)
        @jwks_cache = body["keys"] || []
        @jwks_fetched_at = Time.now

        cache_control_max_age(response.headers).tap do |max|
          @jwks_max_age = max if max
        end

        @jwks_cache
      end

      def cache_control_max_age(headers)
        cc = headers["cache-control"] || headers["Cache-Control"]
        return nil unless cc
        m = cc.match(/max-age=(\d+)/)
        m && m[1].to_i
      end

      def fresh?(fetched_at, max_age)
        fetched_at && (Time.now - fetched_at) < max_age
      end

      def expired?(payload)
        exp = payload["exp"]
        return false unless exp
        Time.at(exp) < Time.now
      end

      # Beltic uses W3C Status List 2021 — a gzip+base64-encoded bitstring where
      # bit `statusListIndex` for credential's `statusListCredential` indicates
      # revocation (1 = revoked).
      def revoked?(payload)
        status = payload.dig("vc", "credentialStatus") || payload["credentialStatus"]
        return false unless status

        index = status["statusListIndex"].to_i
        list_url = status["statusListCredential"] || config.status_list_url
        bitstring = load_status_list!(list_url)
        return false unless bitstring

        byte_index = index / 8
        bit_in_byte = 7 - (index % 8)
        return false if byte_index >= bitstring.bytesize

        ((bitstring.getbyte(byte_index) >> bit_in_byte) & 1) == 1
      end

      def load_status_list!(url)
        return @status_list_cache if @status_list_cache && fresh?(@status_list_fetched_at, @status_list_max_age) && @status_list_url_used == url

        response = Faraday.get(url)
        raise VerificationError, "Status List fetch failed: #{response.status}" unless response.success?
        body = JSON.parse(response.body)
        encoded = body.dig("credentialSubject", "encodedList") || body["encodedList"]
        return nil unless encoded

        gz = b64u_decode(encoded)
        @status_list_cache = Zlib::GzipReader.new(StringIO.new(gz)).read
        @status_list_fetched_at = Time.now
        @status_list_url_used = url
        @status_list_cache
      end

      # Evaluates the credential's claims.permissions array against the
      # transaction context. A permission matches if its resource_type and one
      # of its actions match, and every condition in its conditions array
      # passes.
      def evaluate_policy(payload, ctx)
        return { ok: true, detail: "no context to evaluate" } if ctx.nil? || ctx.empty?

        ctx = ctx.transform_keys(&:to_s)
        claims = payload.dig("vc", "credentialSubject", "claims") || payload["claims"] || {}
        permissions = claims["permissions"] || []
        return { ok: false, detail: "credential has no permissions" } if permissions.empty?

        matching = permissions.select { |p| permission_matches?(p, ctx) }
        return { ok: false, detail: "no permission grants this resource/action" } if matching.empty?

        failures = matching.flat_map { |p| failing_conditions(p, ctx) }.compact
        return { ok: false, detail: "conditions denied: #{failures.join(", ")}" } if failures.any?

        spend_limit = claims["spend_limit"]
        if spend_limit && ctx["transaction_amount"]
          if ctx["transaction_amount"].to_i > spend_limit["amount"].to_i &&
             spend_limit["period"] == "per_transaction"
            return { ok: false, detail: "transaction_amount exceeds per-transaction spend_limit" }
          end
        end

        { ok: true }
      end

      def permission_matches?(permission, ctx)
        return false if permission["resource_type"] && permission["resource_type"] != ctx["resource_type"]
        actions = permission["actions"] || []
        return false if actions.any? && ctx["action"] && !actions.include?(ctx["action"])
        true
      end

      OPS = {
        "lte" => ->(a, b) { a.to_f <= b.to_f },
        "lt"  => ->(a, b) { a.to_f <  b.to_f },
        "gte" => ->(a, b) { a.to_f >= b.to_f },
        "gt"  => ->(a, b) { a.to_f >  b.to_f },
        "eq"  => ->(a, b) { a == b },
        "neq" => ->(a, b) { a != b },
        "in"  => ->(a, b) { Array(b).include?(a) },
      }.freeze

      def failing_conditions(permission, ctx)
        (permission["conditions"] || []).map do |c|
          op = c["operator"]
          field = c["field"]
          expected = c["value"]
          actual = ctx[field]
          checker = OPS[op]
          if checker.nil? || actual.nil? || !checker.call(actual, expected)
            "#{field} #{op} #{expected.inspect} (was #{actual.inspect})"
          end
        end.compact
      end
    end
  end
end

module Houston
  module Beltic
    class Issuer
      def initialize(client)
        @client = client
      end

      # Issue Houston's own business credential (one-time KYB bootstrap).
      def issue_business(subject:, claims:, ttl: "P1Y")
        post_credential(
          credential_type: "business",
          self_attestation_complete: true,
          subject: subject,
          claims:  claims,
          ttl:     ttl,
        )
      end

      # Issue a user credential after the user completes self-attestation.
      def issue_user(subject:, claims:, evidence_refs: [], ttl: "P1Y")
        post_credential(
          credential_type: "user",
          self_attestation_complete: true,
          subject:       subject,
          claims:        claims,
          evidence_refs: evidence_refs,
          ttl:           ttl,
        )
      end

      # Issue an agent_authorization credential delegating from a user to an agent.
      # Beltic REQUIRES delegated_by_subject_id when any permission.resource_type == "wallet"
      # (FinCEN AML). We enforce this client-side too.
      def issue_agent_authorization(subject:, claims:, ttl: nil)
        validate_delegation!(claims)
        body = {
          credential_type: "agent_authorization",
          self_attestation_complete: true,
          subject: subject,
          claims:  claims,
        }
        body[:ttl] = ttl if ttl
        post_credential(body)
      end

      def revoke(credential_id, reason: nil)
        body = reason ? { reason: reason } : {}
        @client.post("/credentials/#{credential_id}/revoke", body)
      end

      def get(credential_id)
        @client.get("/credentials/#{credential_id}")
      end

      private

      def post_credential(body)
        @client.post("/credentials", body)
      end

      def validate_delegation!(claims)
        permissions = claims[:permissions] || claims["permissions"] || []
        return if permissions.empty?

        wallet_scoped = permissions.any? do |p|
          (p[:resource_type] || p["resource_type"]) == "wallet"
        end
        return unless wallet_scoped

        delegated = claims[:delegated_by_subject_id] || claims["delegated_by_subject_id"]
        return if delegated && !delegated.to_s.empty?

        raise DelegationMissingError.new(
          "agent_authorization with wallet-scoped permissions requires delegated_by_subject_id (FinCEN AML)",
          code: "delegated_by_required",
        )
      end
    end
  end
end

module Webhooks
  class BelticController < ActionController::Base
    # Beltic webhook receiver. Verifies HMAC, updates the relevant VC row,
    # fires a Houston observer event for downstream subscribers.
    #
    # Events handled: credential.issued | credential.revoked | credential.suspended
    skip_forgery_protection

    def create
      verifier = Houston::Beltic::WebhookVerifier.new(Houston::Beltic.config.webhook_secret)
      verifier.verify!(
        request.raw_post,
        request.headers[Houston::Beltic::WebhookVerifier::SIGNATURE_HEADER],
        request.headers[Houston::Beltic::WebhookVerifier::TIMESTAMP_HEADER],
      )

      event = JSON.parse(request.raw_post)
      apply_event(event)

      head :ok
    rescue Houston::Beltic::WebhookSignatureError
      head :unauthorized
    rescue JSON::ParserError
      head :bad_request
    end

    private

    # Beltic webhook event shape (see Beltic platform: shared/audit-events.ts):
    #   { id, event_type, credential_id, credential_type, subject_type,
    #     outcome, outcome_reason, timestamp, intervention_required, ... }
    def apply_event(event)
      credential_id = event["credential_id"]
      return unless credential_id

      vc = VerifiableCredential.find_by(credential_id: credential_id)
      return unless vc

      case event["event_type"]
      when "credential.revoked", "credential.deleted"
        vc.update!(status: "revoked", revoked_at: Time.current)
      when "credential.suspended"
        vc.update!(status: "suspended")
      when "credential.issued", "credential.reactivated"
        vc.update!(status: "active")
      end

      Houston.observer.fire("beltic.credential_status_changed",
                            credential: vc,
                            event_type: event["event_type"])
    end
  end
end

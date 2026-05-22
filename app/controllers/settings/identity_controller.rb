module Settings
  class IdentityController < ApplicationController
    before_action :authenticate_user!

    # GET /settings/identity
    def show
      @credential = current_user.beltic_user_credential
      @trust_level = current_user.beltic_trust_level || "unverified"
      @evidence = @credential&.evidence_refs || []
      @recent_events = recent_status_events
    end

    private

    # Recent webhook-driven status changes for this user's credential.
    # Returns at most 10 events. Stubbed for now — replace with real audit log
    # once Webhooks::BelticController persists them.
    def recent_status_events
      []
    end
  end
end

class IdentityVerificationsController < ApplicationController
  before_action :authenticate_user!

  # GET /identity_verification/new
  # Renders the self-attestation modal (Figma: "Verify Your Identity").
  def new
    @existing = current_user.beltic_user_credential
  end

  # POST /identity_verification
  # Creates a pending VC row and enqueues an async issuance job.
  # Beltic enforces `self_attestation_complete: true` server-side; we only
  # set it to true after the user has actually checked the consent boxes.
  def create
    unless attestation_complete?
      flash[:error] = "Please confirm all declarations before submitting."
      render :new, status: :unprocessable_entity and return
    end

    # Beltic schema constraint: if id_document_type is set, id_document_country
    # must also be set, and trust_level must be idv_verified (or higher). Enforce
    # client-side so the user sees a clear error before we POST to Beltic.
    if params[:id_document_type].present? && params[:id_document_country].blank?
      flash[:error] = "Provide the ID document's issuing country when selecting a document type."
      render :new, status: :unprocessable_entity and return
    end

    Beltic::IssueCredentialJob.perform_later(
      kind:    :user,
      user_id: current_user.id,
      claims:  user_claims_from_params,
    )

    redirect_to settings_identity_path,
                notice: "Submitted — Beltic is issuing your credential. You'll see it here in a moment."
  end

  # DELETE /identity/verify
  # Revokes the user's active Beltic credential. Cascades: all of the user's
  # agent_authorization credentials become unusable (their delegated_by_subject_id
  # points at a revoked credential) — Houston's verifier denies them.
  def destroy
    cred = current_user.beltic_user_credential
    if cred&.active?
      Houston::Beltic.issuer.revoke(cred.credential_id, reason: "revoked_by_user")
      cred.update!(status: "revoked", revoked_at: Time.current)
    end
    current_user.update!(beltic_user_credential: nil, beltic_trust_level: nil)

    redirect_to settings_identity_path, notice: "Identity credential revoked."
  end

  private

  def attestation_complete?
    %w[confirm_accuracy consent_issuance understand_revocation].all? do |key|
      ActiveModel::Type::Boolean.new.cast(params.dig(:declarations, key))
    end
  end

  def user_claims_from_params
    {
      kyc_status:           "approved",
      trust_level:          determine_trust_level,
      nationality:          params[:nationality],
      date_of_birth:        params[:date_of_birth],
      id_document_type:     params[:id_document_type].presence,
      id_document_country:  params[:id_document_country].presence,
      parent_business_id:   Houston::Beltic.config.org_subject_id,
    }.compact
  end

  def determine_trust_level
    params[:id_document_type].present? ? "idv_verified" : "self_attested"
  end
end

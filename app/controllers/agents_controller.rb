class AgentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_verified_identity

  # GET /agents/new
  # Renders the same form as agent_authorizations/new but for a brand-new agent.
  def new
    @agent = current_user.agents.build
    @user_credential = current_user.beltic_user_credential
    render "agent_authorizations/new"
  end

  # POST /agents
  # Creates the Agent row, then enqueues Beltic agent_authorization issuance.
  def create
    @agent = current_user.agents.build(agent_params)
    @agent.did = generate_did
    @agent.status = "active"

    if @agent.save
      Beltic::IssueCredentialJob.perform_later(kind: :agent_authorization, agent_id: @agent.id)
      redirect_to settings_agents_path,
                  notice: "#{@agent.name} created. Beltic is issuing the authorization credential."
    else
      @user_credential = current_user.beltic_user_credential
      render "agent_authorizations/new", status: :unprocessable_entity
    end
  end

  private

  def require_verified_identity
    return if current_user.beltic_user_credential&.active?
    redirect_to new_identity_verification_path,
                alert: "Verify your identity before authorizing an agent."
  end

  def agent_params
    params.require(:agent).permit(
      :name,
      :spend_limit_amount_cents,
      :spend_limit_currency,
      :spend_limit_period,
      :per_transaction_max_cents,
      :max_idle_duration_iso8601,
      :confirmation_threshold_cents,
      :confirmation_mode,
      authorized_currencies: [],
    )
  end

  # Real implementation would generate a JWK keypair (likely client-side or in
  # a secure enclave) and derive the DID from it. Stubbed here.
  def generate_did
    "did:jwk:#{SecureRandom.urlsafe_base64(32)}"
  end
end

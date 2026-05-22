class AgentAuthorizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_agent

  # GET /agents/:agent_id/authorization/new
  # Renders the agent-authorization consent modal (Figma: "Authorize this agent").
  def new
    @user_credential = current_user.beltic_user_credential

    unless @user_credential&.active?
      redirect_to new_identity_verification_path,
                  alert: "Verify your identity before authorizing an agent."
      return
    end
  end

  # POST /agents/:agent_id/authorization
  def create
    @agent.assign_attributes(agent_params)

    if @agent.save
      Beltic::IssueCredentialJob.perform_later(
        kind:     :agent_authorization,
        agent_id: @agent.id,
      )
      redirect_to settings_agents_path,
                  notice: "Authorizing #{@agent.name}. Beltic is issuing the credential."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /agents/:agent_id/authorization
  # Revokes the agent's current authorization credential. Idempotent.
  def destroy
    cred = @agent.authorization_credential
    if cred
      Houston::Beltic.issuer.revoke(cred.credential_id, reason: "revoked_by_user")
      cred.update!(status: "revoked", revoked_at: Time.current)
    end
    @agent.update!(status: "revoked")

    redirect_to settings_agents_path, notice: "#{@agent.name} revoked."
  end

  private

  def load_agent
    @agent = current_user.agents.find(params[:agent_id])
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
end

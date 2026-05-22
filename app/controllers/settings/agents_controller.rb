module Settings
  class AgentsController < ApplicationController
    before_action :authenticate_user!

    # GET /settings/agents
    def index
      @agents = current_user.agents.order(:created_at)
    end

    # GET /settings/agents/:id
    def show
      @agent = current_user.agents.find(params[:id])
      @credential = @agent.authorization_credential
    end
  end
end

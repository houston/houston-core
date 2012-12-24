class ProjectDashboardController < ApplicationController
  
  def index
    @project = Project.find_by_slug!(params[:slug])
    @tickets = []
    @tickets = @project.ticket_system.find_tickets!("status-neq-closed") # <-- returns native tickets, not Houston tickets...
  end
  
end

class ProjectDashboardController < ApplicationController
  
  def index
    @project = Project.find_by_slug!(params[:slug])
    @tickets = []
    @tickets = @project.ticket_tracker.find_tickets!("status-neq-closed").map(&:raw_attributes) # <-- returns native tickets, not Houston tickets...
  end
  
end

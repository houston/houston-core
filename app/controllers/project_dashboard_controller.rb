class ProjectDashboardController < ApplicationController
  
  def index
    @project = Project.find_by_slug!(params[:slug])
    @tickets = []
    @tickets = @project.ticket_system.find_tickets!("status-neq-closed") if @project.ticket_system
    
    @dependency_versions = KeyDependency.versions
  end
  
end

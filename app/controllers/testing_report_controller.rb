class TestingReportController < ApplicationController
  
  
  def index
    @title = "Testing Report"
    
    # Faster; one fetch to Unfuddle for all projects
    unfuddle_tickets = Unfuddle.instance.find_tickets!(status: :resolved, resolution: :fixed)
    
    @tickets = []
    @projects = Project.where(ticket_tracker_name: "Unfuddle")
    
    @projects.each do |project|
      next unless can?(:show, project.testing_notes.build)
      
      tickets_for_project = unfuddle_tickets
        .select { |ticket| ticket["project_id"].to_s == project.extended_attributes["unfuddle_project_id"] }
        .map { | attributes| project.ticket_tracker.build_ticket(attributes) }
      tickets = project.tickets
        .includes(:testing_notes)
        .includes(:commits)
        .synchronize(tickets_for_project)
        .reject(&:in_development?)
      
      @tickets.concat tickets
    end
    
    @tickets = TicketPresenter.new(@tickets).with_testing_notes
    render json: @tickets if request.xhr?
  end
  
  
  def show
    @project = Project.find_by_slug!(params[:slug])
    @title = "Testing Report: #{@project.name}"
    authorize! :show, @project.testing_notes.build
    
    @tickets = @project.tickets
      .unclosed
      .fixed
      .includes(:project)
      .includes(:testing_notes)
      .includes(:releases)
      .includes(:commits)
      .reject(&:in_development?)
    @projects = [@project]
    
    @tickets = TicketPresenter.new(@tickets).with_testing_notes
    render json: @tickets if request.xhr?
  end
  
  
end

class TestingReportController < ApplicationController
  
  
  def index
    @title = "Testing Report"
    
    # Faster; one fetch to Unfuddle for all projects
    unfuddle_tickets = Unfuddle.instance.find_tickets!(status: :resolved, resolution: :fixed)
    
    @tickets = []
    
    Project.all.each do |project|
      next unless can?(:show, project.testing_notes.build)
      
      tickets_for_project = unfuddle_tickets
        .select { |ticket| ticket["project_id"] == project.ticket_tracker_id }
        .map { | attributes| project.ticket_tracker.build_ticket(attributes) }
      tickets = project
        .tickets_from_unfuddle_tickets(tickets_for_project)
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
    
    @tickets = @project.find_tickets(status: :resolved, resolution: :fixed).reject(&:in_development?)
    
    @tickets = TicketPresenter.new(@tickets).with_testing_notes
    render json: @tickets if request.xhr?
  end
  
  
end

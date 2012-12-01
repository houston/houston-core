class TestingReportController < ApplicationController
  
  
  def index
    @title = "Testing Report"
    
    unfuddle_tickets = Unfuddle.instance.find_tickets!(status: :resolved, resolution: :fixed)
    
    @projects = []
    @tickets_by_project_id = {}
    
    Project.all.each do |project|
      tickets_for_project = unfuddle_tickets.select { |ticket| ticket["project_id"] == project.unfuddle_id }
      tickets = project
        .tickets_from_unfuddle_tickets(tickets_for_project)
        .reject(&:in_development?)
      
      next unless tickets.any?
      
      @projects << project
      @tickets_by_project_id[project.id] = TicketPresenter.new(tickets).with_testing_notes
    end
    
    render json: @tickets_by_project_id if request.xhr?
  end
  
  
  def show
    @project = Project.find_by_slug!(params[:slug])
    @title = "Testing Report: #{@project.name}"
    
    @tickets = @project.find_tickets(status: :resolved, resolution: :fixed)
     .reject(&:in_development?)
    
    @tickets_by_project_id = {@project.id => TicketPresenter.new(@tickets).with_testing_notes}
    
    render json: @tickets_by_project_id if request.xhr?
  end
  
  
end

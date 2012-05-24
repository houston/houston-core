class TestingReportController < ApplicationController
  
  
  def show
    @project = Project.find_by_slug!(params[:slug])
    @tickets = @project.tickets.in_queues("in_testing", "in_testing_production")
  end
  
  
end

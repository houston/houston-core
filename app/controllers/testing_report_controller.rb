class TestingReportController < ApplicationController
  
  
  def index
    @projects = Project.all.each_with_object({}) do |project, hash|
      tickets = project.tickets.in_queues("in_testing", "in_testing_production")
      hash[project] = tickets if tickets.any?
    end
  end
  
  
  def show
    @project = Project.find_by_slug!(params[:slug])
    @tickets = @project.tickets.in_queues("in_testing", "in_testing_production")
  end
  
  
end

class IntelligenceController < ApplicationController
  
  def index
    @durations = TicketQueue.average_time_for_queues
  end
  
  def show
    @project = Project.find_by_slug!(params[:slug])
    @durations = TicketQueue.average_time_for_queues_for_project(@project)
    render action: "index"
  end
  
end

class KanbanController < ApplicationController
  
  
  def index
    @title = "Kanban"
    
    @projects = Project.where("unfuddle_id IS NOT NULL")
    @durations = TicketQueue.average_time_for_queues
  end
  
  
  # def queue
  #   render :json => TicketPresenter.new(@project.tickets_in_queue(params[:queue]))
  # end
  
  
end

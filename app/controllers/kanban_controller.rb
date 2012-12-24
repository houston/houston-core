class KanbanController < ApplicationController
  
  
  def index
    @title = "Kanban"
    
    @projects = Project.with_ticket_tracking
  end
  
  
  # def queue
  #   render :json => TicketPresenter.new(@project.tickets_in_queue(params[:queue]))
  # end
  
  
end

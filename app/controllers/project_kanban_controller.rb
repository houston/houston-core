class ProjectKanbanController < ApplicationController
  before_filter :find_project
  
  
  def index
    @projects = Project.where("unfuddle_id IS NOT NULL")
  end
  
  
  def queue
    @queue = params[:queue]
    @tickets = @project.tickets_in_queue(@queue)
    respond_to do |format|
      format.html # queue.html.erb
      format.json { render :json => TicketPresenter.new(@tickets) }
    end
  end
  
  
private
  
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
  
end

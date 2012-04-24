class ProjectKanbanController < ApplicationController
  before_filter :find_project
  
  
  def index
    @projects = Project.where("unfuddle_id IS NOT NULL")
  end
  
  
  def queue
    @queue = KanbanQueue.find_by_slug(params[:queue])
    respond_to do |format|
      format.html do
        
        # Render existing tickets
        # !todo: figure out when the last refresh was and do a fresh pull if stale
        @tickets = @project.tickets.in_queue(@queue)
      end
      format.json do
        
        # Always render the freshest tickets
        @tickets = @project.tickets_in_queue(@queue)
        render :json => TicketPresenter.new(@tickets)
      end
    end
  end
  
  
private
  
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
  
end

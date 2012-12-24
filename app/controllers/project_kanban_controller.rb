class ProjectKanbanController < ApplicationController
  before_filter :find_project
  before_filter :no_cache, :only => [:queue]
  
  
  def index
    @title = "Kanban: #{@project.name}"
    
    @projects = Project.with_ticket_tracking
  end
  
  
  def queue
    @queue = KanbanQueue.find_by_slug(params[:queue])
    respond_to do |format|
      format.html do
        
        # Render existing tickets
        # !todo: figure out when the last refresh was and do a fresh pull if stale
        @tickets = @project.tickets.in_queue(@queue).includes(:commits).reorder(:summary)
      end
      format.json do
        
        # Always render the freshest tickets
        begin
          @tickets = @project.tickets_in_queue(@queue)
        rescue Unfuddle::UnauthorizedError
          @tickets = []
        end
        response.headers["X-Revision"] = revision
        render :json => TicketPresenter.new(@tickets).with_testing_notes
      end
    end
  end
  
  
private
  
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
  
end

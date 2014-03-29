class ProjectKanbanController < ApplicationController
  before_filter :find_project
  before_filter :no_cache, :only => [:queue]
  
  
  def index
    @title = "Kanban: #{@project.name}"
    
    @projects = Project.unretired
  end
  
  
  def queue
    @queue = KanbanQueue.find_by_slug(params[:queue])
    @tickets = @project.tickets
      .includes(:project)
      .includes(:ticket_queues)
      .in_queue(@queue, :refresh)
    
    respond_to do |format|
      format.html do
        @tickets = @tickets.sort_by(&:summary)
      end
      format.json do
        response.headers["X-Revision"] = revision
        render json: KanbanTicketPresenter.new(@tickets).as_json
      end
    end
  end
  
  
private
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
end

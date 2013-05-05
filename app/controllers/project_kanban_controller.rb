class ProjectKanbanController < ApplicationController
  before_filter :find_project
  before_filter :no_cache, :only => [:queue]
  
  
  def index
    @title = "Kanban: #{@project.name}"
    
    @projects = Project.where(ticket_tracker_name: "Unfuddle")
  end
  
  
  def queue
    @queue = KanbanQueue.find_by_slug(params[:queue])
    @tickets = []
    @errors = []
    
    # Always render the freshest tickets
    begin
      @tickets = @project.tickets_in_queue(@queue)
    rescue Unfuddle::UnauthorizedError, Houston::Adapters::TicketTracker::InvalidQueryError
      @errors << "#{@project.name} is not configured correctly for use with Houston Kanban:\n#{$!.message}"
    end
    
    respond_to do |format|
      format.html do
        @tickets = @tickets.sort_by(&:summary)
      end
      format.json do
        response.headers["X-Revision"] = revision
        
        if @errors.any?
          render :json => {errors: @errors}
        else
          render :json => TicketPresenter.new(@tickets).with_testing_notes
        end
      end
    end
  end
  
  
private
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
end

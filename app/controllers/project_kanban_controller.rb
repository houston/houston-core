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
        @tickets = @project.tickets.in_queue(@queue).includes(:commits).order(:summary)
      end
      format.json do
        
        # Always render the freshest tickets
        @tickets = @project.tickets_in_queue(@queue)
        render :json => TicketPresenter.new(@tickets)
      end
    end
  end
  
  
  def assign_ticket_to_queue
    ticket = @project.find_or_create_ticket_by_number(params[:ticket_number])
    if ticket
      ticket.set_queue! params[:queue]  
      render :json => TicketPresenter.new(ticket)
    else
      render :json => {errors: ["Ticket could not be found."]}, :status => :unprocessable_entity
    end
  end
  
  
  def remove_ticket_from_queue
    ticket = @project.find_or_create_ticket_by_number(params[:ticket_number])
    if ticket
      ticket.set_queue! nil
      head :ok
    else
      render :json => {errors: ["Ticket could not be found."]}, :status => :unprocessable_entity
    end
  end
  
  
private
  
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
  
end

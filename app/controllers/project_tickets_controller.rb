class ProjectTicketsController < ApplicationController
  before_filter :find_project
  
  
  def index
    render json: TicketPresenter.new(@project.tickets).with_extended_attributes
  end
  
  
  def new
    @tickets = @project.tickets.includes(:project).map do |ticket|
      { id: ticket.id,
        summary: ticket.summary,
        closed: ticket.closed_at.present?,
        ticketUrl: ticket.ticket_tracker_ticket_url,
        number: ticket.number }
    end
  end
  
  
  def create
    attributes = params[:ticket]
    md = attributes[:summary].match(/^\s*\[(\w+)\]\s*(.*)$/) || [nil, "", attributes[:summary]]
    attributes.merge!(type: md[1].capitalize(), summary: md[2])
    attributes.merge!(reporter: current_user)
    
    ticket = @project.create_ticket! attributes
    
    if ticket.persisted?
      render json: TicketPresenter.new(ticket), status: :created, location: ticket.ticket_tracker_ticket_url
    else
      render json: ticket.errors, status: :unprocessable_entity
    end
  end
  
  
private
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
end

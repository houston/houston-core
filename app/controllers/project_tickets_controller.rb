class ProjectTicketsController < ApplicationController
  before_filter :find_project
  before_filter :api_authenticate!, :only => :create
  
  
  
  def index
    render json: TicketPresenter.new(@project.tickets)
  end
  
  def open
    render json: TicketPresenter.new(@project.tickets.includes(:project).unclosed)
  end
  
  
  def new
    unless @project.has_ticket_tracker?
      render template: "project_tickets/no_ticket_tracker"
      return
    end
    
    @labels = []
    @labels = Houston::TMI::TICKET_LABELS_FOR_MEMBERS if @project.slug =~ /^360|members$/
    @labels = Houston::TMI::TICKET_LABELS_FOR_UNITE if @project.slug == "unite"
    benchmark "\e[33mLoad tickets\e[0m" do
      @tickets = @project.tickets
        .pluck(:id, :summary, :number, :closed_at)
        .map do |id, summary, number, closed_at|
        { id: id,
          summary: summary,
          closed: closed_at.present?,
          ticketUrl: @project.ticket_tracker_ticket_url(number),
          number: number }
      end
    end
    
    if request.xhr?
      render json: MultiJson.dump({
        tickets: @tickets,
        project: { slug: @project.slug, ticketTrackerName: @project.ticket_tracker_name },
        labels: @labels
      })
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

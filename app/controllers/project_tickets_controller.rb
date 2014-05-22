class ProjectTicketsController < ApplicationController
  before_filter :find_project
  before_filter :find_ticket, only: [:show, :close, :reopen]
  before_filter :api_authenticate!, :only => :create
  helper ExcelHelpers
  
  
  
  def index
    return render json: TicketPresenter.new(@project.tickets) if request.format.json?
    
    if request.format.xls?
      response.headers["Content-Disposition"] = "attachment; filename=\"#{@project.name} Tickets.xls\""
    end
    
    @tickets = TicketReport.new(@project.tickets).to_a
  end
  
  def open
    render json: TicketPresenter.new(@project.tickets.includes(:project).unclosed)
  end
  
  
  def show
    redirect_to @ticket.ticket_tracker_ticket_url unless @project.ticket_tracker_name == "Houston"
  end
  
  
  def new
    unless @project.has_ticket_tracker?
      render template: "project_tickets/no_ticket_tracker"
      return
    end
    
    @labels = []
    @labels = Houston::TMI::TICKET_LABELS_FOR_MEMBERS if @project.slug =~ /^360|members$/
    @labels = Houston::TMI::TICKET_LABELS_FOR_UNITE if @project.slug == "unite"
    Houston.benchmark "Load tickets" do
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
  
  
  def close
    authorize! :close, @ticket
    @ticket.close!
    redirect_to project_ticket_path(slug: @project.slug, number: @ticket.number)
  end

  def reopen
    authorize! :close, @ticket
    @ticket.reopen!
    redirect_to project_ticket_path(slug: @project.slug, number: @ticket.number)
  end


private
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
  def find_ticket
    @ticket = @project.tickets.find_by_number!(params[:number])
  end

end

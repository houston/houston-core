class SprintsController < ApplicationController
  attr_reader :sprint
  
  before_filter :authenticate_user!
  before_filter :find_sprint, only: [:show, :lock, :add_ticket, :remove_ticket]
  
  
  def current
    @sprint = Sprint.current || Sprint.create!
    show
  end
  
  
  def show
    authorize! :read, sprint
    @open_tickets = Ticket.joins(:project).includes(:project)
      .unclosed
      .unresolved
      .able_to_estimate # <-- knows about Houston scheduler
    @tickets = @sprint.tickets.includes(:checked_out_by)
    render template: "sprints/show"
  end
  
  
  def lock
    authorize! :manage, sprint
    sprint.lock!
    head :ok
  end
  
  
  def add_ticket
    authorize! :update, sprint
    ticket = ::Ticket.find(params[:ticket_id])
    ticket.update_column :sprint_id, sprint.id
    render json: SprintTicketPresenter.new(ticket).to_json
  end
  
  def remove_ticket
    authorize! :update, sprint
    Ticket.where(id: params[:ticket_id]).update_all(sprint_id: nil)
    head :ok
  end
  
  
private
  
  def find_sprint
    @sprint = Sprint.find(params[:id])
  end
  
end

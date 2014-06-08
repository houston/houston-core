class TicketsController < ApplicationController
  before_filter :find_ticket, only: [:show, :update, :close, :reopen]
  
  attr_reader :ticket
  
  def show
    render json: FullTicketPresenter.new(ticket)
  end
  
  def update
    params[:last_release_at] = params.fetch(:lastReleaseAt, params[:last_release_at])
    attributes = params.pick(:last_release_at, :priority, :summary, :description)

    if ticket.update_attributes(attributes)
      render json: []
    else
      render json: ticket.errors, status: :unprocessable_entity
    end
  end
  
  def new
    @projects = followed_projects.select(&:has_ticket_tracker?)
  end
  
  def close
    authorize! :close, ticket
    ticket.close!
    render json: []
  rescue
    render json: [$!.message], status: :unprocessable_entity
  end
  
  def reopen
    authorize! :close, ticket
    ticket.reopen!
    render json: []
  rescue
    render json: [$!.message], status: :unprocessable_entity
  end
  
private
  
  def find_ticket
    @ticket = Ticket.find(params[:id])
    @ticket.updated_by = current_user
  end
  
end

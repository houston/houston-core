class TicketsController < ApplicationController
  before_filter :find_ticket, only: [:show, :update, :close, :reopen]
  
  attr_reader :ticket
  
  def show
    render json: FullTicketPresenter.new(ticket)
  end
  
  def update
    params[:last_release_at] = params.fetch(:lastReleaseAt, params[:last_release_at])
    attributes = params.pick(:last_release_at, :priority, :summary, :description)

    ticket.updated_by = current_user
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
    ticket.updated_by = current_user
    ticket.close!
    render json: []
  rescue
    render json: [$!.message], status: :unprocessable_entity
  end
  
  def reopen
    ticket.updated_by = current_user
    ticket.reopen!
    render json: []
  rescue
    render json: [$!.message], status: :unprocessable_entity
  end
  
private
  
  def find_ticket
    @ticket = Ticket.find(params[:id])
  end
  
end

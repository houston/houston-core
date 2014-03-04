class TicketsController < ApplicationController
  
  def show
    ticket = Ticket.find(params[:id])
    render :json => TicketPresenter.new(ticket).with_testing_notes
  end
  
  def update
    ticket = Ticket.find(params[:id])
    params[:last_release_at] = params.fetch(:lastReleaseAt, params[:last_release_at])
    attributes = params.pick(:last_release_at, :priority)
    
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
    ticket = Ticket.find(params[:id])
    ticket.close_ticket!
    render json: [], :status => :ok
  rescue
    render json: [$!.message], :status => :unprocessable_entity
  end
  
  def reopen
    ticket = Ticket.find(params[:id])
    ticket.reopen!
    render json: [], :status => :ok
  rescue
    render json: [$!.message], :status => :unprocessable_entity
  end
  
end

class TicketsController < ApplicationController
  
  def update
    ticket = Ticket.find(params[:id])
    if ticket.update_attributes(last_release_at: params[:lastReleaseAt])
      render json: [], :status => :ok
    else
      render json: ticket.errors, :status => :unprocessable_entity
    end
  end
  
  def close
    ticket = Ticket.find(params[:id])
    ticket.close_ticket!
    render json: [], :status => :ok
  rescue
    render json: [$!.message], :status => :unprocessable_entity
  end
  
end

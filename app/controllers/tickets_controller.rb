class TicketsController < ApplicationController
  
  def update
    ticket = Ticket.find(params[:id])
    if ticket.update_attributes(last_release_at: params[:lastReleaseAt])
      render json: [], :status => :ok
    else
      render json: ticket.errors, :status => :unprocessable_entity
    end
  end
  
end

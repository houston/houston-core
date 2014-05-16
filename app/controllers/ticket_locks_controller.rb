class TicketLocksController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_ticket
  
  
  def create
    if @ticket.checked_out?
      render json: {base: ["Ticket ##{@ticket.number} is already checked out by #{@ticket.checked_out_by.name}"]}, status: 422
    else
      @ticket.update_attributes!(checked_out_at: Time.now, checked_out_by: current_user)
      head :ok
    end
  end
  
  
  def destroy
    if !@ticket.checked_out?
      head :ok
    elsif @ticket.checked_out_by_id != current_user.id
      render json: {base: ["Ticket ##{@ticket.number} is checked out by #{@ticket.checked_out_by.name}. You cannot check it in"]}, status: 422
    else
      @ticket.update_attributes!(checked_out_at: nil, checked_out_by: nil)
      head :ok
    end
  end
  
  
private
  
  
  def find_ticket
    @ticket = Ticket.find(params[:id])
  end
  
  
end

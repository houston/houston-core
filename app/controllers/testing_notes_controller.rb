class TestingNotesController < ApplicationController
  before_filter :find_ticket
  before_filter :find_testing_note, :only => [:destroy, :update]
  before_filter :authenticate_user!, :only => [:create, :update, :destroy]
  
  rescue_from UserCredentials::MissingCredentials do
    response.headers["X-Credentials"] = "Missing Credentials"
    head 401
  end
  
  rescue_from Unfuddle::UnauthorizedError do
    response.headers["X-Credentials"] = "Invalid Credentials"
    head 401
  end
  
  
  def create
    @testing_note = current_user.testing_notes.build(params[:testing_note].merge(project: @ticket.project))
    
    authorize! :create, @testing_note
    @testing_note.save
    render_testing_note
  end
  
  
  def update
    authorize! :update, @testing_note
    
    @testing_note.update_attributes(params[:testing_note])
    render_testing_note
  end
  
  
  def destroy
    authorize! :destroy, @testing_note
    
    @testing_note.destroy
    head 204
  end
  
  
private
  
  def find_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end
  
  def find_testing_note
    @testing_note = @ticket.testing_notes.find(params[:id])
  end
  
  def render_testing_note
    if @testing_note.errors.any?
      render json: @testing_note.errors, :status => :unprocessable_entity
    else
      render json: TestingNotePresenter.new(@testing_note)
    end
  end
  
end

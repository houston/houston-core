class TestingNotesController < ApplicationController
  before_filter :find_ticket
  before_filter :find_testing_note, :only => [:destroy, :update]
  before_filter :authenticate_user!, :only => [:create, :update, :destroy]
  after_filter :check_failing_verdict, :only => [:create, :update]
  
  
  def create
    @testing_note = current_user.testing_notes.create(params[:testing_note])
    render_testing_note
  end
  
  
  def update
    @testing_note.update_attributes(params[:testing_note])
    render_testing_note
  end
  
  
  def destroy
    @testing_note.destroy
    head 204
  end
  
  
private
  
  def check_failing_verdict
    verdict = params[:testing_note][:verdict]
    if verdict == "fails"
      ChangelogMailer::failed_verdict(@testing_note).deliver
    end
  end
  
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

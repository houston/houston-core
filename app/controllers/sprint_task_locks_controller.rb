class SprintTaskLocksController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_sprint_and_task
  
  attr_reader :sprint, :task
  
  
  def create
    if task.checked_out?(sprint)
      render json: {base: ["Task ##{task.shorthand} is already checked out"]}, status: 422
    else
      task.check_out!(sprint, current_user)
      head :ok
    end
  end
  
  
  def destroy
    if task.checked_out_by_me?(sprint, current_user)
      task.check_in!(sprint)
      head :ok
    elsif task.checked_out?(sprint)
      render json: {base: ["Ticket ##{task.shorthand} is checked out. You cannot check it in"]}, status: 422
    else
      head :ok
    end
  end
  
  
private
  
  def find_sprint_and_task
    @sprint = Sprint.find params[:id]
    @task = Task.find params[:task_id]
  end
  
end

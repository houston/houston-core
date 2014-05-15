class TaskLocksController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_task
  
  
  def create
    if @task.checked_out?
      render json: {base: ["Task ##{@task.shorthand} is already checked out by #{@task.checked_out_by.name}"]}, status: 422
    else
      @task.update_attributes!(checked_out_at: Time.now, checked_out_by: current_user)
      head :ok
    end
  end
  
  
  def destroy
    if !@task.checked_out?
      head :ok
    elsif @task.checked_out_by_id != current_user.id
      render json: {base: ["Ticket ##{@task.shorthand} is checked out by #{@task.checked_out_by.name}. You cannot check it in"]}, status: 422
    else
      @task.update_attributes!(checked_out_at: nil, checked_out_by: nil)
      head :ok
    end
  end
  
  
private
  
  def find_task
    @task = Task.find(params[:id])
  end
  
end

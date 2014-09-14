class TasksController < ApplicationController
  before_filter :find_task
  
  attr_reader :task
  
  def update
    project = task.project
    authorize! :estimate, project
    effort = params[:effort]
    effort = effort.to_d if effort
    effort = nil if effort && effort <= 0
    task.updated_by = current_user
    task.update_attributes effort: effort
    render json: [], status: :ok
  end
  
  def complete
    # !todo: authorize completing a task
    task.complete! unless task.completed?
    render json: TaskPresenter.new(task)
  end
  
  def reopen
    # !todo: authorize completing a task
    task.reopen! unless task.open?
    render json: TaskPresenter.new(task)
  end
  
private
  
  def find_task
    @task = Task.find params[:id]
  end
  
end

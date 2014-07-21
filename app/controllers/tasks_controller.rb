class TasksController < ApplicationController
  
  
  def update
    task = Task.find params[:id]
    project = task.project
    authorize! :estimate, project
    effort = params[:effort]
    effort = effort.to_d if effort
    effort = nil if effort && effort <= 0
    task.updated_by = current_user
    task.update_attributes effort: effort
    render json: [], status: :ok
  end
  
  
end

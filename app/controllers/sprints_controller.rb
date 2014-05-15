class SprintsController < ApplicationController
  attr_reader :sprint
  
  before_filter :authenticate_user!
  before_filter :find_sprint, only: [:show, :lock, :add_task, :remove_task]
  
  
  def current
    @sprint = Sprint.current || Sprint.create!
    show
  end
  
  
  def show
    authorize! :read, sprint
    @open_tasks = Task.open
      .joins(:ticket)
      .joins("INNER JOIN projects ON tickets.project_id=projects.id")
      .merge(Ticket.able_to_estimate)  # <-- knows about Houston scheduler
    @tasks = @sprint.tasks.includes(:checked_out_by)
    render template: "sprints/show"
  end
  
  
  def lock
    authorize! :manage, sprint
    sprint.lock!
    head :ok
  end
  
  
  def add_task
    authorize! :update, sprint
    task = Task.find(params[:task_id])
    task.update_column :sprint_id, sprint.id
    render json: SprintTaskPresenter.new(task).to_json
  end
  
  def remove_task
    authorize! :update, sprint
    Task.where(id: params[:task_id]).update_all(sprint_id: nil)
    head :ok
  end
  
  
private
  
  def find_sprint
    @sprint = Sprint.find(params[:id])
  end
  
end

class SprintsController < ApplicationController
  attr_reader :sprint
  
  before_filter :authenticate_user!
  before_filter :find_sprint, only: [:show, :lock, :add_task, :remove_task]
  
  
  def current
    @sprint = Sprint.current || Sprint.create!
    redirect_to sprint
  end
  
  
  def show
    authorize! :read, sprint
    @open_tasks = Task.joins(:ticket => :project).merge(Ticket.open)
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
    
    # Putting a task into a Sprint implies that you're able to estimate this ticket
    task.ticket.able_to_estimate! if task.ticket.respond_to?(:able_to_estimate!)
    
    if task.completed?
      render text: "Task ##{task.shorthand} cannot be added to the Sprint because it has been completed",
        status: :unprocessable_entity
    else
      task.update_column :sprint_id, sprint.id
      render json: SprintTaskPresenter.new(task).to_json
    end
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

class SprintsController < ApplicationController
  attr_reader :sprint
  
  before_filter :authenticate_user!, except: [:dashboard]
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
  
  
  def dashboard
    @title = "Sprint"
    @sprint = Sprint.find_by_id(params[:id]) || Sprint.current || Sprint.create!
    
    respond_to do |format|
      format.json { render json: {
        start: @sprint.start_date,
        tasks: TaskPresenter.new(@sprint.tasks).as_json } }
      format.html { render layout: "dashboard" }
    end
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
    
    if task.completed? && task.completed_at < sprint.starts_at
      render text: "Task ##{task.shorthand} cannot be added to the Sprint because it was completed before the Sprint began", status: :unprocessable_entity
    else
      sprint.tasks.add task
      render json: SprintTaskPresenter.new(task).to_json
    end
  end
  
  def remove_task
    authorize! :update, sprint
    SprintTask.where(sprint_id: sprint.id, task_id: params[:task_id]).delete_all
    head :ok
  end
  
  
private
  
  def find_sprint
    @sprint = Sprint.find(params[:id])
  end
  
end

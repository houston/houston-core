class SprintsController < ApplicationController
  attr_reader :sprint, :task
  
  before_filter :authenticate_user!, except: [:dashboard]
  before_filter :find_sprint, only: [:show, :lock, :add_task, :remove_task]
  before_filter :find_task, only: [:add_task, :remove_task]
  
  
  def current
    @sprint = Sprint.current || Sprint.create!
    redirect_to sprint
  end
  
  
  def show
    authorize! :read, sprint
    @title = "Sprint #{sprint.end_date.strftime("%-m/%d")}"
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
        tasks: SprintTaskPresenter.new(@sprint).as_json } }
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
    
    if sprint.locked? && !task.ticket_id.in?(sprint.ticket_ids)
      render text: "The Sprint is locked. You can add tasks for tickets that are already in the Sprint, but you can't add new tickets to the Sprint.", status: :unprocessable_entity
      return
    end
    
    # Putting a task into a Sprint implies that you're able to estimate this ticket
    task.ticket.able_to_estimate! if task.ticket.respond_to?(:able_to_estimate!)
    
    if task.completed? && task.completed_at < sprint.starts_at
      render text: "Task ##{task.shorthand} cannot be added to the Sprint because it was completed before the Sprint began", status: :unprocessable_entity
    elsif task.effort.nil? or task.effort.zero?
      render text: "Task ##{task.shorthand} cannot be added to the Sprint because it has no effort", status: :unprocessable_entity
    else
      sprint.tasks.add task
      render json: SprintTaskPresenter.new(sprint, task).to_json
    end
  end
  
  def remove_task
    authorize! :update, sprint
    
    if sprint.locked?
      render text: "The Sprint is locked; tasks cannot be removed", status: :unprocessable_entity
      return
    end
    
    SprintTask.where(sprint_id: sprint.id, task_id: task.id).delete_all
    head :ok
  end
  
  
private
  
  def find_sprint
    @sprint = Sprint.find(params[:id])
  end
  
  def find_task
    @task = Task.find(params[:task_id])
  end
  
end

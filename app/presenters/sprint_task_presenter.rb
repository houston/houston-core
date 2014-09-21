class SprintTaskPresenter < TaskPresenter
  attr_reader :sprint, :ends_at
  
  def initialize(sprint, tasks=sprint.tasks)
    @sprint = sprint
    @ends_at = sprint.end_date.end_of_day
    super tasks
  end
  
  def task_to_json(task)
    super.merge(
      released: task.first_release_at && task.first_release_at < ends_at,
      committed: task.first_commit_at && task.first_commit_at < ends_at,
      completed: task.completed_at && task.completed_at < ends_at,
      checkedOutAt: checked_out_at(task),
      checkedOutBy: checked_out_by(task))
  end
  
private
  
  def checked_out_at(task)
    checked_out(task)[:at]
  end
  
  def checked_out_by(task)
    user_id = checked_out(task)[:by]
    users[user_id] if user_id
  end
  
  def checked_out(task)
    locks.fetch(task.id, {})
  end
  
  def locks
    @locks ||= Hash[SprintTask.where(sprint_id: sprint.id, task_id: tasks.map(&:id))
      .pluck(:task_id, :checked_out_at, :checked_out_by_id)
      .map { |task_id, at, id| [task_id, {at: at, by: id}] }]
  end
  
  def users
    @users ||= Hash[User.where(id: locks.values.map { |attrs| attrs[:by] })
      .pluck(:id, :email, :first_name)
      .map { |id, email, first_name| [id,
        { id: id,
          email: email,
          firstName: first_name }] }]
  end
  
end

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
      checkedOutAt: task.checked_out_at,
      checkedOutBy: present_user(task.checked_out_by))
  end
  
private
  
  def present_user(user)
    return nil unless user
    { id: user.id,
      email: user.email,
      firstName: user.first_name,
      name: user.name }
  end
  
end

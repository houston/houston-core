class SprintTaskPresenter < TaskPresenter
  attr_reader :sprint
  
  def initialize(sprint, tasks=sprint.tasks)
    @sprint = sprint
    super tasks
  end
  
  def task_to_json(task)
    super.merge(
      released: task.first_release_at && task.first_release_at < sprint.end_date,
      committed: task.first_commit_at && task.first_commit_at < sprint.end_date,
      completed: task.completed_at && task.completed_at < sprint.end_date,
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

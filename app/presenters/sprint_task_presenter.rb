class SprintTaskPresenter < TaskPresenter
  
  def task_to_json(task)
    super.merge(
      checkedOutAt: task.checked_out_at,
      checkedOutBy: present_user(task.checked_out_by))
  end
  
private
  
  def present_user(user)
    return nil unless user
    { id: user.id,
      email: user.email,
      name: user.name }
  end
  
end

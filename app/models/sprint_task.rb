class SprintTask < ActiveRecord::Base
  self.table_name = "sprints_tasks"
  
  belongs_to :sprint
  belongs_to :task
  
  def self.checked_out
    where arel_table[:checked_out_by_id].not_eq(nil)
  end
  
  def self.checked_out_by(user)
    where(checked_out_by_id: user.id)
  end
  
  def self.not_checked_out
    where(checked_out_by_id: nil)
  end
  
  def self.check_out!(user)
    update_all(checked_out_at: Time.now, checked_out_by_id: user.id)
  end
  
  def self.check_in!
    update_all(checked_out_at: nil, checked_out_by_id: nil)
  end
  
end

class Milestone < ActiveRecord::Base
  
  belongs_to :project
  has_many :tickets
  
  default_scope where(destroyed_at: nil)
  
  validates :project_id, presence: true
  validates :name, presence: true, uniqueness: {scope: :project_id}
  
  def self.uncompleted
    where(completed_at: nil)
  end
  
  def self.without(milestones)
    without_remote_ids(milestones.map(&:remote_id))
  end
  
  def self.without_remote_ids(*ids)
    where(arel_table[:remote_id].not_in(ids.flatten.map(&:to_i)))
  end
  
  def uncompleted?
    completed_at.nil?
  end
  
end

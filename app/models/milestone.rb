class Milestone < ActiveRecord::Base
  
  belongs_to :project
  has_many :tickets
  
  validates :project_id, presence: true
  validates :name, presence: true, uniqueness: {scope: :project_id}
  
  def self.uncompleted
    where(completed_at: nil)
  end
  
  def uncompleted?
    completed_at.nil?
  end
  
end

class Milestone < ActiveRecord::Base
  extend Nosync
  
  belongs_to :project
  has_many :tickets
  
  versioned only: [:name, :start_date, :end_date, :band]
  
  default_scope { where(destroyed_at: nil).order(:start_date) }
  
  validates :project_id, presence: true
  validates :name, presence: true, uniqueness: {scope: :project_id}
  
  after_save :propagate_name_change, if: :name_changed?
  
  delegate :ticket_tracker, to: :project
  delegate :nosync?, to: "self.class"
  
  class << self
    def uncompleted
      where(completed_at: nil)
    end
    alias :open :uncompleted
    
    def visible
      where(arel_table[:start_date].not_eq(nil)).
      where(arel_table[:end_date].not_eq(nil))
    end
    
    def without(milestones)
      without_remote_ids(milestones.map(&:remote_id))
    end
    
    def without_remote_ids(*ids)
      where(arel_table[:remote_id].not_in(ids.flatten.map(&:to_i)))
    end
    
    def remote_id_map
      query = select("remote_id, id").to_sql
      connection.select_rows(query).each_with_object({}) { |(remote_id, id), map| map[remote_id.to_i] = id.to_i }
    end
  end
  
  def uncompleted?
    completed_at.nil?
  end
  
  def close!
    project.ticket_tracker.close_milestone!(self) if project.ticket_tracker.respond_to?(:close_milestone!)
    touch :completed_at
  end
  
  def remote_milestone
    @remote_milestone ||= ticket_tracker.find_milestone(remote_id) if ticket_tracker.respond_to?(:find_milestone)
  end
  alias :remote :remote_milestone
  
private
  
  def propagate_name_change
    return if nosync?
    remote_milestone.update_name!(name) if remote_milestone.respond_to?(:update_name!)
  end
  
end

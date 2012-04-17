class TicketQueue < ActiveRecord::Base
  
  belongs_to :ticket
  
  validates :ticket, :presence => true
  
  def name
    queue
  end
  
  def destroy
    _run_destroy_callbacks { delete }
  end
  
  def delete
    update_attribute(:destroyed_at, Time.now) if !deleted? && persisted?
    freeze
  end
  
  def destroyed?
    !destroyed_at.nil?
  end
  alias :deleted? :destroyed?
  
  # Returns the amount of time the ticket spent in the given queue (in seconds)
  def queue_time
    end_time = destroyed? ? destroyed_at : Time.now
    end_time - created_at
  end
  
end

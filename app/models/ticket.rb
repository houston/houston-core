class Ticket < ActiveRecord::Base
  
  has_one :ticket_queue, conditions: "destroyed_at IS NULL"
  
  
  validates :summary, presence: true
  validates :number, presence: true
  
  
  def set_queue!(value)
    return if queue == value
    
    Ticket.transaction do
      ticket_queue.destroy if ticket_queue
      create_ticket_queue!(ticket: self, queue: value)
    end
    
    value
  end
  
  def queue
    ticket_queue && ticket_queue.name
  end
  
  
end

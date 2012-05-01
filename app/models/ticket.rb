class Ticket < ActiveRecord::Base
  
  belongs_to :project
  has_one :ticket_queue, conditions: "destroyed_at IS NULL"
  has_many :testing_notes
  
  default_scope includes(:ticket_queue)
  
  validates :project_id, presence: true
  validates :summary, presence: true
  validates :number, presence: true
  validates_uniqueness_of :number, :scope => :project_id
  
  
  class << self
    def in_queue(queue)
      queue = queue.slug if queue.is_a?(KanbanQueue)
      where(["ticket_queues.queue = ?", queue])
    end
    
    def numbered(*numbers)
      numbers = numbers.flatten.map(&:to_i)
      where(:number => numbers)
    end
    
    def attributes_from_unfuddle_ticket(unfuddle_ticket)
      unfuddle_ticket.pick("number", "summary", "description").merge("unfuddle_id" => unfuddle_ticket["id"])
    end
  end
  
  
  def set_queue!(value)
    return if queue == value
    
    Ticket.transaction do
      ticket_queue.destroy if ticket_queue
      create_ticket_queue!(ticket: self, queue: value)
    end
    
    value
  end
  alias :queue= :set_queue!
  
  def queue
    ticket_queue && ticket_queue.name
  end
  
  # Returns the amount of time the ticket has spent in its current queue (in seconds)
  def age
    ticket_queue ? ticket_queue.queue_time : 0
  end
  
  
  
  # c.f. app/assets/models/testing_note.coffee
  def verdict
    verdicts_by_tester = {}
    testing_notes.each do |note|
      tester_id = note.user_id
      if note.verdict == "fails"
        verdicts_by_tester[tester_id] = "failing"
      else
        verdicts_by_tester[tester_id] ||= "passing"
      end
    end
    
    verdicts = verdicts_by_tester.values
    if verdicts.member? "failing"
      "Failing"
    elsif verdicts.length < project.testers.length
      "Pending"
    else
      "Passing"
    end
  end
  
  
  
end

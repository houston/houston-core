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
    
    def with_testing_notes_by(user)
      sql = <<-SQL
        INNER JOIN (
          SELECT ticket_id, COUNT(id) AS count
            FROM testing_notes
            WHERE testing_notes.user_id=#{user.id}
            GROUP BY ticket_id
        ) AS q
          ON tickets.id=q.ticket_id
      SQL
      joins(sql).where("q.count>0")
      
      # joins(:testing_notes) \
      #   .group("tickets.id") \
      #   .where("testing_notes.user_id = ?", user.id) \
      #   .having("COUNT(testing_notes.id) > 0")
    end
    
    def without_testing_notes_by(user)
      testing_notes = Arel::Table.new(:testing_notes)
      tickets = Arel::Table.new(:tickets)
      
      notes = testing_notes \
        .project(testing_notes[:ticket_id], testing_notes[:id].count) \
        .group(testing_notes[:ticket_id])
        
      joins(notes) \
        .on(tickets[:id].eq(notes[:ticket_id])) \
        .having(notes[:id] = 0)
      
      # sql = <<-SQL
      #   LEFT OUTER JOIN (
      #     SELECT ticket_id, COUNT(id) AS count
      #       FROM testing_notes
      #       WHERE testing_notes.user_id=#{user.id}
      #       GROUP BY ticket_id
      #   ) AS q
      #     ON tickets.id=q.ticket_id
      # SQL
      # "q.count IS NULL OR q.count=0"
      
      # joins("LEFT OUTER JOIN testing_notes ON tickets.id = testing_notes.ticket_id") \
      #   .group("tickets.id") \
      #   .having("COUNT(testing_notes.id) = 0")
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
      create_ticket_queue!(ticket: self, queue: value) if value
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

class Ticket < ActiveRecord::Base
  
  belongs_to :project
  has_one :ticket_queue, conditions: "destroyed_at IS NULL"
  has_many :testing_notes
  has_and_belongs_to_many :releases, before_add: :ignore_release_if_duplicate
  
  default_scope includes(:ticket_queue)
  
  validates :project_id, presence: true
  validates :summary, presence: true
  validates :number, presence: true
  validates_uniqueness_of :number, scope: :project_id
  
  
  class << self
    def in_queue(queue)
      queue = queue.slug if queue.is_a?(KanbanQueue)
      where(["ticket_queues.queue = ?", queue])
    end
    
    def in_queues(*queues)
      queues = queues.map { |queue| queue.is_a?(KanbanQueue) ? queue.slug : queue }
      where(["ticket_queues.queue IN (?)", queues])
    end
    
    def with_testing_notes_by(user)
      q = "q#{rand(9999)}"
      sql = <<-SQL
        INNER JOIN (
          SELECT ticket_id, COUNT(id) AS count
            FROM testing_notes
            WHERE testing_notes.user_id=#{user.id}
            GROUP BY ticket_id
        ) AS #{q}
          ON tickets.id=#{q}.ticket_id
      SQL
      joins(sql).where("#{q}.count>0")
    end
    
    def without_testing_notes_by(user)
      q = "q#{rand(9999)}"
      sql = <<-SQL
        LEFT OUTER JOIN (
          SELECT ticket_id, COUNT(id) AS count
            FROM testing_notes
            WHERE testing_notes.user_id=#{user.id}
            GROUP BY ticket_id
        ) AS #{q}
          ON tickets.id=#{q}.ticket_id
      SQL
      joins(sql).where("#{q}.count IS NULL OR #{q}.count=0")
    end
    
    # Tickets where the most recent testing_note
    # by the supplied user has a failing verdict
    # and is _before_ the most recent release
    def to_be_retested_by(user)
      q = "q#{rand(9999)}"
      r = "r#{rand(9999)}"
      sql = <<-SQL
        
        -- 1) Find the most recent failing testing_note
        INNER JOIN (
          SELECT ticket_id, created_at
            FROM testing_notes
            WHERE testing_notes.user_id=#{user.id}
              AND testing_notes.verdict='fails'
            ORDER BY testing_notes.created_at DESC
        ) AS #{q}
          ON tickets.id=#{q}.ticket_id
        
        -- 2) Find the most recent release of this ticket
        INNER JOIN (
          SELECT releases_tickets.ticket_id, releases.created_at
            FROM releases
              INNER JOIN releases_tickets ON releases_tickets.release_id=releases.id
            ORDER BY releases.created_at DESC
        ) AS #{r}
          ON tickets.id=#{r}.ticket_id
      SQL
      joins(sql).where("#{q}.created_at < #{r}.created_at")
    end
    
    def numbered(*numbers)
      numbers = numbers.flatten.map(&:to_i)
      where(:number => numbers)
    end
    
    def attributes_from_unfuddle_ticket(unfuddle_ticket)
      unfuddle_ticket.pick("number", "summary", "description").merge("unfuddle_id" => unfuddle_ticket["id"])
    end
  end
  
  
  def in_queue?(name)
    self.queue == name
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
  
  def last_release_at
    last_release = releases.first
    last_release && last_release.created_at
  end
  
  
  
  # c.f. app/assets/models/ticket.coffee
  def verdict
    return "" if project.testers.none?
    
    verdicts = verdicts_by_tester(testing_notes_since_last_release).values
    if verdicts.member? "failing"
      "Failing"
    elsif verdicts.length < project.testers.length 
      "Pending"
    else
      "Passing"
    end
  end
  
  def verdicts_by_tester(notes)
    verdicts_by_tester = {}
    notes.each do |note|
      tester_id = note.user_id
      if note.verdict == "fails"
        verdicts_by_tester[tester_id] = "failing"
      else
        verdicts_by_tester[tester_id] ||= "passing"
      end
    end
    verdicts_by_tester
  end
  
  def testing_notes_since_last_release
    last_release_at ? testing_notes.where(["created_at > ?", last_release_at]) : testing_notes
  end
  
  
  
  def set_unfuddle_kanban_field_to(id)
    return false if unfuddle_id.blank?
    
    # Transform `field_2` to `field2-value-id`
    attribute = project.kanban_field.gsub(/field_(\d)/, 'field\1-value-id')
    
    remote_ticket = project.ticket_system.ticket(unfuddle_id)
    remote_ticket.update_attribute(attribute, id)
  end
  
  
  
private
  
  
  
  def ignore_release_if_duplicate(release)
    raise ActiveRecord::Rollback if self.releases.exists?(release.id)
  end
  
  
  
end

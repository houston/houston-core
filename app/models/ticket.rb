class Ticket < ActiveRecord::Base
  
  belongs_to :project
  has_one :ticket_queue, conditions: "destroyed_at IS NULL"
  has_many :testing_notes
  has_and_belongs_to_many :releases, before_add: :ignore_release_if_duplicate
  has_and_belongs_to_many :commits
  
  default_scope order(:number).includes(:ticket_queue)
  
  validates :project_id, presence: true
  validates :summary, presence: true
  validates :number, presence: true
  validates_uniqueness_of :number, scope: :project_id, on: :create
  
  remote_model Unfuddle::RemoteTicket
  attr_remote :id => :unfuddle_id,
              :project_id => :unfuddle_project_id,
              :hours_estimate_current => :estimated_effort
  remote_key [:project_id, :id], :path => "/projects/:unfuddle_project_id/tickets/:unfuddle_id"
  expires_after 100.years
  
  # !Override fetch_remote_resource, when this is fetched, set its prefix_options
  def fetch_remote_resource
    super.tap do |resource|
      resource.prefix_options = {project_id: unfuddle_project_id} if resource
    end
  end
  
  
  
  attr_readonly :number, :project_id
  
  delegate :testers, :maintainers, to: :project
  
  
  def unfuddle_project_id
    project.unfuddle_id
  end
  attr_writer :unfuddle_project_id
  
  
  class << self
    def for_projects(*projects)
      ids = projects.flatten.map { |project| project.is_a?(Project) ? project.id : project }
      where(project_id: ids)
    end
    
    def in_queue(queue)
      queue = queue.slug if queue.is_a?(KanbanQueue)
      where(["ticket_queues.queue = ?", queue])
    end
    
    def in_queues(*queues)
      queues = queues.flatten.map { |queue| queue.is_a?(KanbanQueue) ? queue.slug : queue }
      where(["ticket_queues.queue IN (?)", queues])
    end
    
    def open_on(date)
      with_closed_at.where(["tickets.created_at < ? AND (ticket_closures.closed_at IS NULL OR ticket_closures.closed_at > ?)", date, date])
    end
    
    def with_closed_at
      # It's most recent queue will be the one on top; NULLs will be on top
      joins("LEFT OUTER JOIN (SELECT DISTINCT ON (ticket_queues.ticket_id) ticket_queues.ticket_id, ticket_queues.destroyed_at AS closed_at FROM ticket_queues ORDER BY ticket_queues.ticket_id, ticket_queues.destroyed_at DESC) AS ticket_closures ON ticket_closures.ticket_id=tickets.id")
    end
    
    def numbered(*numbers)
      numbers = numbers.flatten.map(&:to_i)
      where(:number => numbers)
    end
    
    def attributes_from_unfuddle_ticket(unfuddle_ticket)
      unfuddle_ticket.pick("number", "summary", "description").merge(
        "estimated_effort" => unfuddle_ticket["hours_estimate_current"],
        "unfuddle_id" => unfuddle_ticket["id"] )
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
  
  def committers
    commits.map { |commit| {name: commit.committer, email: commit.committer_email} }.uniq
  end
  
  def goldmine_numbers
    (goldmine || "").split(",").map(&:strip)
  end
  
  
  
  def in_development?
    deployment.blank?
  end
  
  
  
  def close_ticket!
    unfuddle_ticket = Unfuddle::Ticket.new("id" => unfuddle_id, "project_id" => project.unfuddle_id)
    unfuddle_ticket.update_attributes!("status" => "closed")
    set_queue! nil
    self
  end
  
  
  
  # c.f. app/assets/models/ticket.coffee
  def verdict
    return "" if testers.none?
    
    verdicts = verdicts_by_tester.values
    if verdicts.member? "failing"
      "Failing"
    elsif verdicts.length >= testers.length && verdicts.all? { |verdict| verdict == "passing" }
      "Passing"
    else
      "Pending"
    end
  end
  
  def verdicts_by_tester(notes=testing_notes_since_last_release)
    return {} if notes.empty?
    
    verdicts_by_tester = Hash[testers.map(&:id).zip([nil])]
    notes.each do |note|
      tester_id = note.user_id
      if verdicts_by_tester.key?(tester_id)
        if note.verdict == "fails"
          verdicts_by_tester[tester_id] = "failing"
        elsif note.verdict == "works"
          verdicts_by_tester[tester_id] ||= "passing"
        end
      end
    end
    verdicts_by_tester
  end
  
  def verdicts_by_tester_index
    verdicts = verdicts_by_tester
    testers.each_with_index.each_with_object({}) { |(tester, i), response| response[i + 1] = verdicts[tester.id] if verdicts.key?(tester.id) }
  end
  
  def testing_notes_since_last_release
    last_release_at ? testing_notes.where(["created_at > ?", last_release_at]) : testing_notes
  end
  
  
  
  def set_unfuddle_kanban_field_to(value)
    return false if unfuddle_id.blank?
    
    unfuddle = project.ticket_system
    attribute = unfuddle.get_ticket_attribute_for_custom_value_named!("Fixed in") # e.g. field2_value_id
    id = unfuddle.find_custom_field_value_by_value!("Fixed in", value).id
    
    ticket = unfuddle.ticket(unfuddle_id)
    ticket.update_attribute(attribute, id)
  end
  
  
  
private
  
  
  
  def ignore_release_if_duplicate(release)
    raise ActiveRecord::Rollback if self.releases.exists?(release.id)
  end
  
  
  
end

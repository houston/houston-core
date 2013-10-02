class Ticket < ActiveRecord::Base
  self.inheritance_column = nil
  
  belongs_to :project
  belongs_to :reporter, class_name: "User"
  belongs_to :milestone, counter_cache: true
  has_one :ticket_queue, conditions: "destroyed_at IS NULL"
  has_many :testing_notes
  has_many :ticket_prerequisites, autosave: true
  has_and_belongs_to_many :releases, before_add: :ignore_release_if_duplicate
  has_and_belongs_to_many :commits
  
  default_scope order(:number)
  
  serialize :extended_attributes, ActiveRecord::Coders::Hstore
  
  validates :project_id, presence: true
  validates :summary, presence: true
  validates :number, presence: true
  validates :type, presence: true, inclusion: { in: Houston::TMI::TICKET_TYPES, message: "\"%{value}\" is unknown. It must be #{Houston::TMI::TICKET_TYPES.to_sentence(last_word_connector: ", or ")}" }
  validates_uniqueness_of :number, scope: :project_id, on: :create, if: :number
  
  after_save :propagate_milestone_change, if: :milestone_id_changed?
  
  attr_readonly :number, :project_id
  
  delegate :testers, :maintainers, to: :project
  
  
  
  class << self
    
    def for_projects(*projects)
      ids = projects.flatten.map { |project| project.is_a?(Project) ? project.id : project }
      where(project_id: ids)
    end
    
    def in_queue(queue)
      queue = queue.slug if queue.is_a?(KanbanQueue)
      includes(:ticket_queue).where(["ticket_queues.queue = ?", queue])
    end
    
    def in_queues(*queues)
      queues = queues.flatten.map { |queue| queue.is_a?(KanbanQueue) ? queue.slug : queue }
      includes(:ticket_queue).where(["ticket_queues.queue IN (?)", queues])
    end
    
    def numbered(*numbers)
      where(number: numbers.flatten.map(&:to_i))
    end
    
  end
  
  
  
  def prerequisites=(ticket_numbers)
    existing_prerequisites = self.prerequisites
    
    # Delete any prerequisites that have been removed
    ticket_prerequisites.not_numbered(ticket_numbers).delete_all if existing_prerequisites.any?
    
    # Create any prerequisites that have been added
    new_prerequisites = (ticket_numbers - existing_prerequisites).map { |new_number|
        {project_id: project_id, prerequisite_ticket_number: new_number} }
    
    if new_record?
      ticket_prerequisites.build(new_prerequisites)
    else
      new_prerequisites.each { |attrs| ticket_prerequisites.create(attrs) }
    end
  end
  
  def prerequisites
    ticket_prerequisites.map(&:prerequisite_ticket_number)
  end
  
  
  
  def due_date
    extended_attributes["due_date"]
  end
  
  def due_date=(value)
    extended_attributes["due_date"] = value
    extended_attributes_will_change!
  end
  
  
  
  def in_queue?(name)
    self.queue == name
  end
  
  def set_queue!(value)
    return if queue == value
    
    Ticket.transaction do
      ticket_queue.destroy if ticket_queue
      self.ticket_queue = TicketQueue.create!(ticket: self, queue: value) if value
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
    commits.map { |commit| TicketCommitter.new(commit.committer, commit.committer_email) }.uniq
  end
  
  
  
  
  def ticket_tracker_ticket_url
    project.ticket_tracker_ticket_url(number)
  end
  
  
  
  def in_development?
    deployment.blank?
  end
  
  
  
  def antecedents
    (super || []).map { |s| TicketAntecedent.from_s(self, s) }
  end
  
  def antecedents=(antecedents)
    super antecedents.map(&:to_s)
  end
  
  
  
  def tags
    (super || []).map(&TicketTag.method(:from_s))
  end
  
  def tags=(tags)
    super (tags || []).map(&:to_s)
  end
  
  
  
  def extended_attributes
    super || (self.extended_attributes = {})
  end
  
  
  
  def create_comment!(testing_note)
    return unless remote_ticket.respond_to?(:create_comment!)
    remote_id = remote_ticket.create_comment!(testing_note.to_comment)
    raise RuntimeError, "remote_id must not be nil" unless remote_id
    testing_note.unfuddle_id = remote_id
  end
  
  def update_comment!(testing_note)
    return unless remote_ticket.respond_to?(:update_comment!)
    remote_ticket.update_comment!(testing_note.to_comment)
  end
  
  def destroy_comment!(testing_note)
    return unless remote_ticket.respond_to?(:destroy_comment!)
    remote_ticket.destroy_comment!(testing_note.to_comment)
  end
  
  
  
  def ticket_tracker
    project.ticket_tracker
  end
  
  def remote_ticket
    @remote_ticket ||= project && project.ticket_tracker.find_ticket_by_number(number)
  end
  
  def release!(release)
    self.releases << release unless self.releases.exists?(release.id)
    update_attribute(:last_release_at, release.created_at)
    set_deployment_to!(release.environment_name)
    Houston.observer.fire "ticket:release", self, release
  end
  
  def close_ticket!
    remote_ticket.close! if remote_ticket
    
    set_queue! nil
    self
  end
  
  def set_deployment_to!(environment_name)
    remote_ticket.update_attribute(:deployment, environment_name) if remote_ticket
    
    update_attribute(:deployment, environment_name)
  end
  
  
  
  # c.f. app/assets/models/ticket.coffee
  def verdict
    return "" if testers.none?
    
    verdicts = verdicts_by_tester.values
    if verdicts.member? "failing"
      "Failing"
    elsif verdicts.length >= min_passing_verdicts && verdicts.all? { |verdict| verdict == "passing" }
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
      next unless verdicts_by_tester.key?(tester_id) # not was not by a tester
      
      if note.fail?
        verdicts_by_tester[tester_id] = "failing"
      elsif note.pass?
        verdicts_by_tester[tester_id] ||= "passing"
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
  
  def min_passing_verdicts
    project.min_passing_verdicts
  end
  
  
  
  def participants
    @participants ||= begin              # Participants in a Ticket include:
      User.unretired.where(id:           #
        Array(reporter_id) +             #   - its reporter
        testing_notes.pluck(:user_id) +  #   - anyone who has commented on it
        releases.pluck(:user_id)) +      #   - anyone who has released it
        committers                       #   - anyone who has comitted to it
    end                                  #
  end
  
  
  
  # Not certain if it will be best to use Remotable with Tickets or not
  # By putting this here, dependent code won't have to change if we add
  # Remotable to Tickets again.
  def self.nosync; yield; end
  def self.nosync=(value); end
  def self.nosync?; true; end
  
  
  
  TicketCommitter = Struct.new(:name, :email) do
    
    def tester?
      false
    end
    
    def to_h
      { name: name, email: email }
    end
    
  end
  
  
  
private
  
  def ignore_release_if_duplicate(release)
    raise ActiveRecord::Rollback if self.releases.exists?(release.id)
  end
  
  
  def propagate_milestone_change
    remote_ticket.set_milestone! milestone.remote_id if milestone
  end
  
end

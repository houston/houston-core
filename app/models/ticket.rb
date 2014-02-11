class Ticket < ActiveRecord::Base
  self.inheritance_column = nil
  
  belongs_to :project
  belongs_to :reporter, class_name: "User"
  belongs_to :milestone, counter_cache: true
  belongs_to :sprint
  belongs_to :checked_out_by, class_name: "User"
  has_many :ticket_queues, conditions: "ticket_queues.destroyed_at IS NULL"
  has_many :testing_notes
  has_many :ticket_prerequisites, autosave: true
  has_and_belongs_to_many :releases, before_add: :ignore_release_if_duplicate
  has_and_belongs_to_many :commits, conditions: {unreachable: false}
  
  default_scope order(:number).where(destroyed_at: nil)
  
  serialize :extended_attributes, ActiveRecord::Coders::Hstore
  
  validates :project_id, presence: true
  validates :summary, presence: true
  validates :number, presence: true
  validates :priority, inclusion: { in: %w{low normal high} }
  validates :type, presence: true, inclusion: { in: Houston.config.ticket_types, message: "\"%{value}\" is unknown. It must be #{Houston.config.ticket_types.to_sentence(last_word_connector: ", or ")}" }
  validates_uniqueness_of :number, scope: :project_id, on: :create, if: :number
  
  after_save :propagate_milestone_change, if: :milestone_id_changed?
  
  attr_readonly :number, :project_id
  
  delegate :testers, :maintainers, to: :project
  
  
  
  class << self
    
    def for_projects(*projects)
      ids = projects.flatten.map { |project| project.is_a?(Project) ? project.id : project }
      where(project_id: ids)
    end
    alias :for_project :for_projects
    
    def in_queue(queue, arg=nil)
      if arg == :refresh
        sync_tickets_in_queue(queue)
      else
        includes(:ticket_queues).merge(TicketQueue.named(queue))
      end
    end
    
    def sync_tickets_in_queue(queue)
      queue = KanbanQueue.find_by_slug(queue) unless queue.is_a?(KanbanQueue)
      transaction do
        queue.filter(scoped).tap do |tickets_in_queue|
        
          ticket_ids_were_in_queue = TicketQueue.where(queue: queue.slug).merge(scoped).pluck(:ticket_id)
          ticket_ids_in_queue = tickets_in_queue.pluck(:id)
          TicketQueue.enter! queue, ticket_ids_in_queue - ticket_ids_were_in_queue
          TicketQueue.exit!  queue, ticket_ids_were_in_queue - ticket_ids_in_queue
        
        end
      end
    end
    
    
    
    def numbered(*numbers)
      where(number: numbers.flatten.map(&:to_i))
    end
    
    def without(tickets)
      not_numbered(tickets.map(&:number))
    end
    
    def not_numbered(*numbers)
      where(arel_table[:number].not_in(numbers.flatten.map(&:to_i)))
    end
    
    def unresolved
      unclosed.where(resolution: "")
    end
    
    def resolved
      where(arel_table[:resolution].not_eq(""))
    end
    
    def fixed
      where(resolution: "fixed")
    end
    
    def unclosed
      where(closed_at: nil)
    end
    alias :open :unclosed
    
    def closed
      where(arel_table[:closed_at].not_eq(nil))
    end
    
    def closed_on(date)
      where(closed_at: date.to_time.beginning_of_day..date.to_time.end_of_day)
    end
    
    def deployed
      where(arel_table[:deployment].not_eq(nil))
    end
    
    def deployed_to(environment)
      where(deployment: environment)
    end
    
    def unreleased
      where(arel_table[:deployment].not_eq("Production"))
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
  
  
  
  def exit_queues!
    ticket_queues.exit_all!
  end
  
  
  
  def age_in(queue)
    queue = queue.slug if queue.is_a?(KanbanQueue)
    age_in_queues.fetch(queue, 0)
  end
  
  def age_in_queues
    @age_in_queues ||= Hash[ticket_queues.map { |queue| [queue.queue, queue.queue_time] }]
  end
  
  
  
  def committers
    commits.map { |commit| TicketCommitter.new(commit.committer, commit.committer_email) }.uniq
  end
  
  
  
  def ticket_tracker_ticket_url
    project.ticket_tracker_ticket_url(number)
  end
  
  
  
  def checked_out?
    checked_out_at.present?
  end
  
  def in_current_sprint?
    project.in_current_sprint?(self)
  end
  
  
  
  def unresolved?
    resolution.blank?
  end
  
  def resolved?
    !resolution.blank?
  end
  
  def open?
    closed_at.nil?
  end
  
  def closed?
    closed_at.present?
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
    first_release = self.releases.before(reopened_at).empty?
    self.releases << release unless self.releases.exists?(release.id)
    update_attribute(:first_release_at, release.created_at) if first_release
    update_attribute(:last_release_at, release.created_at)
    set_deployment_to!(release.environment_name)
    Houston.observer.fire "ticket:release", self, release
  end
  
  def resolve!
    remote_ticket.resolve! if remote_ticket and remote_ticket.respond_to?(:resolve!)
    
    update_column :resolution, "fixed"
    self
  end
  
  def close_ticket!
    remote_ticket.close! if remote_ticket
    
    update_column :closed_at, Time.now
    exit_queues!
    self
  end
  
  def reopen!
    raise "Instead of reopening a closed ticket, make a new one!" if closed?
    return unless resolved?
    
    remote_ticket.reopen! if remote_ticket
    
    update_attributes(
      deployment: nil,
      resolution: "",
      reopened_at: Time.now,
      first_release_at: nil,
      last_release_at: nil)
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
  
  
  
  def self.nosync
    value = nosync?
    begin
      self.nosync = true
      yield
    ensure
      self.nosync = value
    end
  end
  
  def self.nosync=(value)
    @nosync = value
  end
  
  def self.nosync?
    !!@nosync
  end
  
  delegate :nosync?, to: "self.class"
  
  
  
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
    return if nosync?
    remote_ticket.set_milestone! milestone && milestone.remote_id
  end
  
end

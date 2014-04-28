class Ticket < ActiveRecord::Base
  extend Nosync
  
  self.inheritance_column = nil
  
  belongs_to :project
  belongs_to :reporter, class_name: "User"
  belongs_to :milestone, counter_cache: true
  belongs_to :sprint
  belongs_to :checked_out_by, class_name: "User"
  has_many :testing_notes
  has_and_belongs_to_many :releases, before_add: :ignore_release_if_duplicate
  has_and_belongs_to_many :commits, -> { where(unreachable: false) }
  has_and_belongs_to_many :released_commits, -> { reachable.released }, class_name: "Commit", association_foreign_key: "commit_id"
  
  default_scope { order(:number).where(destroyed_at: nil) }
  
  validates :project_id, presence: true
  validates :summary, presence: true
  validates :number, presence: true
  validates :priority, inclusion: { in: %w{low normal high} }
  validates :type, presence: true, inclusion: { in: Houston.config.ticket_types, message: "\"%{value}\" is unknown. It must be #{Houston.config.ticket_types.to_sentence(last_word_connector: ", or ")}" }
  validates_uniqueness_of :number, scope: :project_id, on: :create, if: :number
  
  before_save :find_reporter, if: :find_reporter?
  after_save :propagate_milestone_change, if: :milestone_id_changed?
  after_save :resolve_antecedents!, if: :just_resolved?
  after_save :close_antecedents!, if: :just_closed?
  
  attr_readonly :number, :project_id
  
  delegate :testers, :maintainers, :min_passing_verdicts, to: :project
  delegate :nosync?, to: "self.class"
  
  
  
  class << self
    
    def for_projects(*projects)
      ids = projects.flatten.map { |project| project.is_a?(Project) ? project.id : project }
      where(project_id: ids)
    end
    alias :for_project :for_projects
    
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
    
    def created_before(time)
      where(arel_table[:created_at].lt(time)).reorder(arel_table[:created_at].desc)
    end
    
    def closed_before(time)
      where(arel_table[:closed_at].lt(time)).reorder(arel_table[:closed_at].desc)
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
  
  
  
  def due_date
    extended_attributes["due_date"]
  end
  
  def due_date=(value)
    extended_attributes["due_date"] = value
    extended_attributes_will_change!
  end
  
  
  
  def reporter_email=(value)
    value = value.downcase if value
    super(value)
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
  
  def unreleased?
    releases.before(reopened_at).empty?
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
    self.releases << release unless releases.exists?(release.id)
    cache_release_attributes(release)
    Houston.observer.fire "ticket:release", self, release
  end
  
  def cache_release_attributes(release)
    attributes = { last_release_at: release.created_at, deployment: release.environment_name }
    attributes.merge!(first_release_at: release.created_at) if unreleased?
    remote_ticket.update_attribute(:deployment, release.environment_name) if remote_ticket # <-- !todo: remove
    update_attributes attributes
  end
  
  def resolve!
    remote_ticket.resolve! if remote_ticket and remote_ticket.respond_to?(:resolve!)
    
    update_attribute :resolution, "fixed"
    self
  end
  
  def close!
    remote_ticket.close! if remote_ticket
    
    update_attribute :closed_at, Time.now
    self
  end
  alias :close_ticket! :close!
  
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
  
  
  
  def testing_notes_since_last_release
    last_release_at ? testing_notes.where(["created_at > ?", last_release_at]) : testing_notes
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
  
  
  
  class TicketCommitter < Struct.new(:name, :email)
    
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
  
  def find_reporter?
    reporter_email_changed? or (reporter_email.present? and reporter_id.nil?)
  end
  
  def find_reporter
    self.reporter = User.with_email_address(reporter_email).first
  end
  
  def propagate_milestone_change
    return if nosync?
    remote_ticket.set_milestone! milestone && milestone.remote_id
  end
  
  def just_resolved?
    resolution_changed? && resolution_was.blank?
  end
  
  def just_closed?
    closed_at_changed? && closed_at_was.nil?
  end
  
  def resolve_antecedents!
    antecedents.each(&:resolve!)
  end
  
  def close_antecedents!
    antecedents.each(&:close!)
  end
  
end

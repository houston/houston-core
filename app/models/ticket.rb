class Ticket < ActiveRecord::Base
  extend Nosync

  self.inheritance_column = nil

  versioned only: [:summary, :description, :type,
                   :tags, :prerequisites,
                   :closed_at, :resolution, :milestone_id]

  belongs_to :project
  belongs_to :reporter, class_name: "User"
  belongs_to :milestone, counter_cache: true
  has_many :tasks, validate: false
  has_and_belongs_to_many :commits, -> { where(unreachable: false) }

  default_scope { order(:number).where(destroyed_at: nil) }

  validates :project_id, presence: true
  validates :summary, presence: true
  validates :number, presence: true
  validates :priority, inclusion: { in: %w{low normal high} }
  validates :type, presence: true, inclusion: { in: Houston.config.ticket_types, message: "\"%{value}\" is unknown. It must be #{Houston.config.ticket_types.to_sentence(last_word_connector: ", or ")}" }
  validate :must_have_at_least_one_task
  validates_uniqueness_of :number, scope: :project_id, on: :create

  before_validation :ensure_that_ticket_has_a_task
  before_save :parse_ticket_description, if: :description_changed?
  before_save :find_reporter, if: :find_reporter?
  after_save :propagate_milestone_change, if: :milestone_id_changed?
  after_save :updated_milestone_attributes

  attr_readonly :number, :project_id

  delegate :ticket_tracker, to: :project
  delegate :nosync?, to: "self.class"



  class << self

    def for_projects(*projects)
      ids = projects.flatten.map { |project| project.is_a?(Project) ? project.id : project }
      where(project_id: ids)
    end
    alias :for_project :for_projects

    def mentioned_by_commits(*commits)
      ids = commits.flatten.map { |commit| commit.is_a?(Commit) ? commit.id : commit }
      commits_tickets = CommitTicket.arel_table
      where arel_table[:id].in(commits_tickets
        .where(commits_tickets[:commit_id].in(ids))
        .project(commits_tickets[:ticket_id]))
    end

    def numbered(*numbers)
      where(number: numbers.flatten.map(&:to_i))
    end

    def not_numbered(*numbers)
      where(arel_table[:number].not_in(numbers.flatten.map(&:to_i)))
    end

    def ideas
      where(type: %w{Feature Enhancement})
    end

    def bugs
      where(type: %w{Bug Chore})
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

    def estimated
      # !todo: will change: must be defined in terms of tasks
      where("NULLIF(tickets.extended_attributes->'estimated_effort', '')::numeric > 0")
    end

    def unestimated
      # !todo: will change: must be defined in terms of tasks
      where("NOT defined(tickets.extended_attributes, 'estimated_effort') OR NULLIF(tickets.extended_attributes->'estimated_effort', '')::numeric <= 0")
    end

    def resolve_all!
      return unless Rails.env.production?
      all.parallel.each do |ticket|
        Houston.try 3, exceptions_matching(/connection reset by peer/i) do
          ticket.resolve!
        end
      end
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



  def tags
    (super || []).map(&TicketTag.method(:from_s))
  end

  def tags=(tags)
    super (tags || []).map(&:to_s)
  end



  def extended_attributes
    super || (self.extended_attributes = {})
  end



  def commit_time
    @commit_time ||= commits.map(&:committer_hours).compact.sum
  end

  def effort
    @effort ||= tasks.map(&:effort).sum
  end



  def create_comment!(comment)
    remote.create_comment!(comment) if remote.respond_to?(:create_comment!)
  end

  def update_comment!(comment)
    remote.update_comment!(comment) if remote.respond_to?(:update_comment!)
  end

  def destroy_comment!(comment)
    remote.destroy_comment!(comment) if remote.respond_to?(:destroy_comment!)
  end



  def resolve!
    remote_ticket.resolve! if remote_ticket.respond_to?(:resolve!)
    update_attribute :resolution, "fixed"
  end

  def close!
    remote_ticket.close! if remote_ticket
    update_attribute :closed_at, Time.now
  end

  def unclose!
    remote_ticket.reopen! if remote_ticket
    update_attribute :closed_at, nil
  end

  def reopen!
    return unless resolved?
    remote_ticket.reopen! if remote_ticket

    update_attributes(
      resolution: "",
      closed_at: nil,
      deployment: nil) # <-- !todo: is this necessary?
  end



private

  def find_reporter?
    reporter_email_changed? or (reporter_email.present? and reporter_id.nil?)
  end

  def find_reporter
    self.reporter = User.with_email_address(reporter_email).first
  end

  def propagate_milestone_change
    return if nosync?
    remote_ticket.set_milestone!(milestone && milestone.remote_id) if remote_ticket.respond_to?(:set_milestone!)
  end

  def just_resolved?
    resolution_changed? && resolution_was.blank?
  end

  def just_closed?
    closed_at_changed? && closed_at_was.nil?
  end

  def remote_ticket
    @remote_ticket ||= ticket_tracker.find_ticket_by_number(number)
  end
  alias :remote :remote_ticket

  def parse_ticket_description
    Houston.config.parse_ticket_description(self)
  end

  def ensure_that_ticket_has_a_task
    tasks.build if tasks.none?
  end

  def must_have_at_least_one_task
    errors.add :base, "must have at least one task" if tasks.length.zero?
  end

  def updated_milestone_attributes
    return unless milestone_id
    return unless new_record? or closed_at_changed?
    milestone.update_closed_tickets_count!
  end

end

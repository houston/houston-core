class Release < ActiveRecord::Base

  after_create :load_commits!, :if => :can_read_commits?
  after_create :release_each_ticket!
  after_create :release_each_task!
  after_create :release_each_antecedent!
  after_create { Houston.observer.fire "release:create", self }

  belongs_to :project
  belongs_to :user
  belongs_to :deploy
  belongs_to :commit_before, class_name: "Commit"
  belongs_to :commit_after, class_name: "Commit"
  has_and_belongs_to_many :commits, autosave: false # <-- a bug with autosave causes commit_ids to be saved twice
  has_and_belongs_to_many :tickets, autosave: false # <-- a bug with autosave causes ticket_ids to be saved twice
  has_many :tasks, through: :commits

  default_scope { order("created_at DESC") }

  delegate :maintainers, :to => :project

  validates_presence_of :user_id
  validates_uniqueness_of :deploy_id, :allow_nil => true
  validates_associated :release_changes



  class << self
    def to_environment(environment_name)
      where(environment_name: environment_name)
    end
    alias :to :to_environment

    def for_projects(*projects)
      ids = projects.flatten.map { |project| project.is_a?(Project) ? project.id : project }
      where(project_id: ids)
    end

    def for_deploy(deploy)
      where(deploy_id: deploy.id)
    end

    def most_recent_commit
      release = where(arel_table[:commit1].not_eq("")).first
      release ? release.commit1 : Houston::NULL_GIT_COMMIT
    end

    def before(time)
      return all if time.nil?
      where(arel_table[:created_at].lt(time))
    end

    def after(time)
      return all if time.nil?
      where(arel_table[:created_at].gt(time))
    end

    def latest
      first
    end

    def earliest
      last
    end

    def with_message
      where arel_table[:message].not_eq("")
    end

    def most_recent
      joins <<-SQL
        INNER JOIN (
          SELECT project_id, environment_name, MAX(created_at) AS created_at
          FROM releases
          GROUP BY project_id, environment_name
        ) AS most_recent_releases
        ON releases.project_id=most_recent_releases.project_id
        AND releases.environment_name=most_recent_releases.environment_name
        AND releases.created_at=most_recent_releases.created_at
      SQL
    end
  end



  def commit0
    super || commit_before.try(:sha)
  end

  def commit0=(sha)
    super; self.commit_before = identify_commit(sha)
  end

  def commit1
    super || commit_after.try(:sha)
  end

  def commit1=(sha)
    super; self.commit_after = identify_commit(sha)
  end

  def can_read_commits?
    (commit_before.present? || commit0 == Houston::NULL_GIT_COMMIT) && commit_after.present?
  end

  def environment_name=(value)
    super value.downcase
  end



  attr_reader :commit_not_found_error_message



  def released_at
    deploy ? deploy.completed_at : created_at
  end

  def release_date
    released_at.to_date
  end
  alias :date :release_date



  def name
    release_date.strftime("%A, %b %e, %Y")
  end

  def message=(value)
    super value.to_s.strip
  end

  def release_changes
    super.lines.map { |s| ReleaseChange.from_s(self, s) }
  end

  def release_changes=(changes)
    super changes.map(&:to_s).join("\n")
  end

  def release_changes_attributes=(params)
    self.release_changes = params.values
      .reject { |attrs| attrs["_destroy"] == "1" }
      .map { |attrs| ReleaseChange.new(self, attrs["tag_slug"], attrs["description"]) }
  end



  def build_changes_from_commits
    self.release_changes = commits
      .map { |commit| ReleaseChange.from_commit(self, commit) }
      .reject { |change| change.tag.nil? }
  end

  def load_commits!
    self.commits = project.commits.between(commit_before, commit_after)
  end

  def load_tickets!
    self.tickets = project.tickets.mentioned_by_commits(commits)
  end



  def antecedents
    @antecedents ||= (tickets.map(&:antecedents) + commits.map(&:antecedents))
      .flatten
      .uniq
      .sort
  end



  def ignore?
    !show_release_notes_for?(environment_name)
  end

  def notification_recipients
    @notification_recipients ||= project.followers.unretired
  end



private

  def identify_commit(sha)
    project.find_commit_by_sha(sha)
  rescue Houston::Adapters::VersionControl::CommitNotFound
    @commit_not_found_error_message = $!.message
    @commit_not_found_error_message << " in the repo \"#{project.repo}\"" if project
    nil
  rescue Houston::Adapters::VersionControl::InvalidShaError
    @commit_not_found_error_message = $!.message
    nil
  end

  def release_each_ticket!
    tickets.each do |ticket|
      ticket.released!(self)
    end
  end

  def release_each_task!
    tasks.each do |task|
      task.released!(self)
    end
  end

  def release_each_antecedent!
    antecedents.each do |antecedent|
      antecedent.released!(self)
    end
  end

end

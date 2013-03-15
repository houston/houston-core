class Release < ActiveRecord::Base
  
  after_create :load_commits!, :if => :can_read_commits?
  after_create :release_each_ticket
  after_create { Houston.observer.fire "release:create", self }
  
  belongs_to :project
  belongs_to :user
  belongs_to :deploy
  has_many :changes, :dependent => :destroy
  has_many :commits, :dependent => :destroy, :autosave => true
  
  default_scope order("created_at DESC")
  
  accepts_nested_attributes_for :changes, :allow_destroy => true
  
  delegate :maintainers, :to => :project
  
  validates_presence_of :user_id
  # validates_presence_of :deploy_id, :on => :create
  validates_uniqueness_of :deploy_id, :allow_nil => true
  validates_associated :changes
  
  
  
  def self.to_environment(environment_name)
    where(environment_name: environment_name)
  end
  
  def self.for_deploy(deploy)
    where(deploy_id: deploy.id)
  end
  
  def self.most_recent_commit
    (release = first) && release.commit1
  end
  
  
  
  def can_read_commits?
    valid_sha?(commit0) && valid_sha?(commit1)
  end
  
  def valid_sha?(sha)
    sha.present?
  end
  
  attr_reader :commit_not_found_error_message
  
  
  
  def released_at
    deploy ? deploy.created_at : created_at
  end
  
  def release_date
    released_at.to_date
  end
  alias :date :release_date
  
  
  
  def name
    release_date.strftime("%A, %b %e, %Y")
  end
  
  
  
  def build_changes_from_commits
    commits.each do |commit|
      changes.build Change.attributes_from_commit(commit).merge(release: self) unless commit.skip?
    end
  end
  
  def load_commits!
    native_commits.each do |native|
      commit = commits.find_by_sha(native.sha)
      attributes = Commit.attributes_from_native_commit(native).merge(release: self)
      if commit
        commit.update_attributes(attributes)
      else
        commits.build(attributes)
      end
    end
  end
  
  
  
  def ticket_numbers
    commits.each_with_object([]) { |commit, ticket_numbers|
      ticket_numbers.concat commit.ticket_numbers }
  end
  
  def load_tickets!
    project.find_or_create_tickets_by_number(ticket_numbers)
  end
  
  def tickets
    @tickets ||= load_tickets!
  end
  
  
  
  def goldmine_numbers
    @goldmine_numbers ||= tickets.each_with_object([]) { |ticket, numbers| numbers.concat(ticket.goldmine_numbers) }.uniq
  end
  
  
  
  def notification_recipients
    @notification_recipients ||= begin
      user_ids = project.notifications.where(environment_name: environment_name).pluck(:user_id)
      User.where(id: user_ids)
    end
  end
  
  
  
private
  
  
  def native_commits
    project.repo.commits_between(commit0, commit1)
  rescue Houston::VersionControl::CommitNotFound
    @commit_not_found_error_message = $!.message
    @commit_not_found_error_message << " in the repo \"#{project.version_control_location}\"" if project
    []
  rescue Houston::VersionControl::InvalidShaError
    @commit_not_found_error_message = $!.message
    []
  end
  
  def release_each_ticket
    tickets.each do |ticket|
      ticket.release!(self)
    end
  end
  
  
  
end

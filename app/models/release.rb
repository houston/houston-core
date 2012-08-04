class Release < ActiveRecord::Base
  
  after_create :load_commits!, :if => :can_read_commits?
  after_create :associate_tickets_with_self
  after_create { Changelog.observer.fire "release:create", self }
  
  belongs_to :environment
  belongs_to :user
  has_many :changes, :dependent => :destroy
  has_many :commits, :dependent => :destroy, :autosave => true
  
  default_scope order("created_at DESC")
  
  default_value_for :name do; Time.now.strftime("%A, %b %e, %Y %H:%M:%S"); end
  
  accepts_nested_attributes_for :changes, :allow_destroy => true
  
  delegate :project, :to => :environment
  delegate :maintainers, :to => :project
  
  validates_presence_of :user_id
  
  
  
  def can_read_commits?
    (commit0.blank? || valid_sha?(commit0)) && valid_sha?(commit1)
  end
  
  def valid_sha?(sha)
    sha.present?
  end
  
  
  
  def git_commits
    return [] unless can_read_commits?
    
    Rails.logger.info "[git] getting commits: #{commit0}..#{commit1}"
    project.repo.commits_between(commit0, commit1)
  end
  
  def build_changes_from_commits
    commits.each do |commit|
      changes.build(description: commit.message, release: self) unless commit.skip?
    end
  end
  
  def load_commits!
    git_commits.each do |grit_commit|
      commit = commits.find_by_sha(grit_commit.sha)
      if commit
        commit.update_attributes Commit.attributes_from_grit_commit(grit_commit)
      else
        commits.build Commit.attributes_from_grit_commit(grit_commit).merge(release: self)
      end
    end
  end
  
  
  
  def ticket_numbers
    [].tap do |ticket_numbers|
      commits.each { |commit| ticket_numbers.concat commit.ticket_numbers }
    end
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
  
  
  
  def update_tickets_in_unfuddle!
    kanban_field_id = environment.resulting_kanban_field_id
    if kanban_field_id
      tickets.each do |ticket|
        ticket.set_unfuddle_kanban_field_to(kanban_field_id)
      end
    end
  end
  
  
  
  def notification_recipients
    @notification_recipients ||= begin
      user_ids = project.notifications.where(environment: environment.slug).pluck(:user_id)
      User.where(id: user_ids)
    end
  end
  
  
  
private
  
  
  
  def associate_tickets_with_self
    tickets.each do |ticket|
      ticket.releases << self unless ticket.releases.exists?(id)
      ticket.update_attribute(:last_release_at, self.created_at)
    end
  end
  
  
  
end

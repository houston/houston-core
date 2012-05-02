class Release < ActiveRecord::Base
  
  after_create :load_commits!, :if => :can_read_commits?
  
  belongs_to :environment
  has_many :changes, :dependent => :destroy
  has_many :commits, :dependent => :destroy, :autosave => true
  
  default_scope order("created_at DESC")
  
  default_value_for :name do; Time.now.strftime("%A, %b %e, %Y %H:%M:%S"); end
  
  accepts_nested_attributes_for :changes, :allow_destroy => true
  
  delegate :project, :to => :environment
  
  
  
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
      changes.build(description: commit.message) unless commit.skip?
    end
  end
  
  def load_commits!
    git_commits.each do |grit_commit|
      commit = commits.find_by_sha(grit_commit.sha)
      if commit
        commit.update_attributes Commit.attributes_from_grit_commit(grit_commit)
      else
        commits.build Commit.attributes_from_grit_commit(grit_commit)
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
  
  
  
end

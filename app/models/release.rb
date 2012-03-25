class Release < ActiveRecord::Base
  
  after_create :load_commits!, :if => :can_read_commits?
  
  belongs_to :environment
  has_many :changes, :dependent => :destroy
  has_many :commits, :dependent => :destroy
  
  default_scope order("created_at DESC")
  
  default_value_for :name do; Time.now.strftime("%A, %b %e, %Y %H:%M:%S"); end
  
  accepts_nested_attributes_for :changes, :allow_destroy => true
  
  delegate :project, :to => :environment
  
  
  
  def can_read_commits?
    [commit0, commit1].all?(&method(:valid_sha?))
  end
  
  def valid_sha?(sha)
    sha.present?
  end
  
  
  
  def git_commits
    can_read_commits? ? project.repo.commits_between(commit0, commit1) : []
  end
  
  def build_changes_from_commits
    git_commits.each do |commit|
      message = commit.message
      changes.build(description: message)
    end
  end
  
  def load_commits!
    git_commits.each do |grit_commit|
      commit = commits.find_by_sha(grit_commit.sha)
      if commit
        commit.update_attributes Commit.attributes_from_grit_commit(grit_commit)
      else
        commits.create Commit.attributes_from_grit_commit(grit_commit)
      end
    end
  end
  
  
end

class Release < ActiveRecord::Base
  
  belongs_to :environment
  has_many :changes, :dependent => :destroy
  has_many :commits, :dependent => :destroy
  
  default_scope order("created_at DESC")
  
  delegate :project, :to => :environment
  
  default_value_for :name do; Time.now.strftime("%A, %b %e, %Y %H:%M:%S"); end
  
  
  def git_commits
    project.repo.commits_between(commit0, commit1)
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

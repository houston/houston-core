class Deploy < ActiveRecord::Base
  
  belongs_to :project
  has_one :release
  belongs_to :commit
  
  before_validation :identify_commit, on: :create
  validates :project_id, :environment_name, presence: true
  validates :sha, presence: {message: "must refer to a commit"}
  
  default_scope { order("created_at DESC") }
  
  after_create { Houston.observer.fire "deploy:create", self }
  
  
  class << self
    def to_environment(environment_name)
      where(environment_name: environment_name)
    end
    alias :to :to_environment
    
    def before(time)
      where(arel_table[:created_at].lt(time))
    end
  end
  
  
  def build_release
    @release ||= Release.new(
      project: project,
      environment_name: environment_name,
      commit0: project.releases.to(environment_name).most_recent_commit,
      commit1: sha,
      deploy: self)
  end
  
  
  def commits
    @commits ||= find_commits
  end
  
  def previous_deploy
    @previous_deploy ||= project.deploys
      .to(environment_name)
      .before(created_at || Time.now)
      .first
  end
  
  def environment
    environment_name
  end
  
  
  
private
  
  def identify_commit
    return unless project && sha
    self.commit = project.find_commit_by_sha(sha)
    self.sha = commit.sha if commit
  rescue Houston::Adapters::VersionControl::InvalidShaError
  end
  
  def find_commits
    return [] unless sha
    return [] unless previous_deploy
    project.commits.between(previous_deploy.sha, sha)
  end
  
end

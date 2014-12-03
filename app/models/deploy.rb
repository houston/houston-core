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
    
    def before(time)
      where(arel_table[:created_at].lteq(time))
    end
  end
  
  
  def build_release
    @release ||= Release.new(
      project: project,
      environment_name: environment_name,
      commit0: project.releases.to_environment(environment_name).most_recent_commit,
      commit1: sha,
      deploy: self)
  end
  
  
  def commits
    @commits ||= find_commits
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
    previous_deploy = project.deploys
      .to_environment(environment_name)
      .before(created_at || Time.now)
      .last
    return [] unless previous_deploy
    project.commits.between(previous_deploy.sha, sha)
  end
  
end

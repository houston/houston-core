class Deploy < ActiveRecord::Base
  include BelongsToCommit
  
  belongs_to :project
  has_one :release
  
  validates :project_id, :environment_name, presence: true
  
  default_scope { order("completed_at DESC") }
  
  after_save :notify_if_completed
  
  
  class << self
    def completed
      where arel_table[:completed_at].not_eq(nil)
    end
    
    def to_environment(environment_name)
      where(environment_name: environment_name)
    end
    alias :to :to_environment
    
    def before(time)
      where arel_table[:completed_at].lt(time)
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
      .completed
      .to(environment_name)
      .before(completed_at || Time.now)
      .first
  end
  
  def completed?
    completed_at.present?
  end
  
  def environment
    environment_name
  end
  
  def output_stream
    @output_stream ||= OutputStream.new(self)
  end
  
  
  
private
  
  def find_commits
    return [] unless sha
    return [] unless previous_deploy
    project.commits.between(previous_deploy.sha, sha)
  end
  
  def notify_if_completed
    if just_completed?
      update_column :duration, completed_at - created_at if duration.nil?
      Houston.observer.fire "deploy:completed", self
    end
  end
  
  def just_completed?
    completed_at_changed? && completed?
  end
  
end

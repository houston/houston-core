class Deploy < ActiveRecord::Base
  
  belongs_to :project
  has_one :release
  
  validates :project_id, :environment_name, :commit, :presence => true
  
  after_create { Houston.observer.fire "deploy:create", self }
  
  
  def build_release
    @release ||= Release.new({
      project: project,
      environment_name: environment_name,
      commit0: project.releases.to_environment(environment_name).most_recent_commit,
      commit1: commit,
      deploy: self
    })
  end
  
  
  def commit=(value)
    super value.strip
  end
  
  
end

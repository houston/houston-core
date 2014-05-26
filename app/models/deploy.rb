class Deploy < ActiveRecord::Base
  attr_accessor :sha
  
  belongs_to :project
  has_one :release
  belongs_to :commit
  
  before_validation :identify_commit, on: :create
  validates :project_id, :environment_name, presence: true
  validates :commit, presence: {message: "must refer to a valid commit"}
  
  after_create { Houston.observer.fire "deploy:create", self }
  
  
  def build_release
    @release ||= Release.new(
      project: project,
      environment_name: environment_name,
      commit0: project.releases.to_environment(environment_name).most_recent_commit,
      commit1: commit.try(:sha),
      deploy: self)
  end
  
  
  def commit=(value)
    return self.sha = value if value.is_a?(String)
    super
  end
  
  
private
  
  def identify_commit
    return unless project && sha
    self.commit = project.find_commit_by_sha(sha)
  rescue Houston::Adapters::VersionControl::InvalidShaError
  end
  
end

class Deploy < ActiveRecord::Base
  
  
  belongs_to :project
  belongs_to :environment
  has_one :release
  
  
  validates :project_id, :environment_id, :commit, :presence => true
  
  
  after_create :prompt_maintainers_to_create_release
  
  
  def build_release
    Release.new({
      environment: environment,
      commit0: environment.last_commit,
      commit1: commit,
      deploy: self
    })
  end
  
  
  def prompt_maintainers_to_create_release
    project.maintainers.each do |maintainer|
      NotificationMailer.on_deploy(build_release, maintainer).deliver!
    end
  # rescue Timeout::Error
  #   render text: "Couldn't get a response from the mail server. Is everything OK?", status: 500
  end
  
  
end

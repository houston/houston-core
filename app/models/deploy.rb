class Deploy < ActiveRecord::Base
  
  
  belongs_to :project
  belongs_to :environment
  
  
  validates :project_id, :environment_id, :commit, :presence => true
  
  
  after_create :prompt_maintainers_to_create_release
  
  
  def prompt_maintainers_to_create_release
    release = environment.releases.new(commit0: environment.last_commit, commit1: commit)
    
    if release.can_read_commits?
      release.load_commits!
      release.load_tickets!
      release.build_changes_from_commits
    end
    
    release.maintainers.each do |maintainer|
      NotificationMailer.on_post_receive(release, maintainer).deliver!
    end
  # rescue Timeout::Error
  #   render text: "Couldn't get a response from the mail server. Is everything OK?", status: 500
  end
  
  
end

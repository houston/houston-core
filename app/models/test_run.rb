class TestRun < ActiveRecord::Base
  
  belongs_to :project
  
  validates_presence_of :project_id, :commit
  
  after_create :trigger_build!
  
  
  
  def self.for(commit)
    find_or_instantiate_by_commit(commit)
  end
  
  
  
  alias_method :start!, :save!
  
  def short_commit
    commit[0...8]
  end
  
  def finished?
    response.present?
  end
  
  def trigger_build!
    Faraday.post(trigger_build_url, {"COMMIT_SHA" => commit, "CALLBACK_URL" => callback_url})
  # rescue Project Doesn't Exist
  #  create the job in Jenkins
  #  https://github.com/john-griffin/jenkins-client
  end
  
  def trigger_build_url
    "http://ci.cphepdev.com/job/#{project.slug}/buildWithParameters"
    # "http://ci.cphepdev.com/job/#{project.slug}/buildWithParameters?COMMIT_SHA=#{commit}&CALLBACK_URL=#{callback_url}"
  end
  
  def callback_url
    Rails.application.routes.url_helpers
      .web_hook_url(project_id: project.slug, hook: "post_build")
  end
  
  def callback_path
    Rails.application.routes.url_helpers
      .web_hook_path(project_id: project.slug, hook: "post_build")
  end
  
  def completed!(results_url)
    update_attributes!(completed_at: Time.now, results_url: results_url)
    fetch_results!
  end
  
  def fetch_results!
    response = Faraday.get(results_url)
    
    # Assumes structure of Jenkins testReport
    results = JSON.parse(response.body)
    self.duration = results[:duration] * 1000 # convert seconds to milliseconds
    self.fail_count = results[:failCount]
    self.pass_count = results[:passCount]
    self.skip_count = results[:skipCount]
    self.details = results[:suites]
    
    self.save!
    
    Houston.observer.fire "test_run:complete", self
  end
  
  
  
end

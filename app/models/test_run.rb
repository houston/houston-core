class TestRun < ActiveRecord::Base
  
  belongs_to :project
  
  validates_presence_of :project_id, :commit
  validates :results_url, :presence => true, :if => :completed?
  
  before_create :trigger_build!
  
  
  
  alias_method :start!, :save!
  
  def short_commit
    commit[0...8]
  end
  
  def completed?
    completed_at.present?
  end
  
  def has_results?
    result.present?
  end
  
  def trigger_build!
    project.ci_job.build!(commit)
  end
  
  def completed!(results_url)
    self.completed_at = Time.now unless completed?
    self.results_url = results_url
    save!
    fetch_results! unless has_results?
  end
  
  def fetch_results!
    attributes = project.ci_job.fetch_results!(results_url)
    update_attributes! attributes
  end
  
  
  
end

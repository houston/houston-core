class TestRun < ActiveRecord::Base
  
  belongs_to :project
  
  validates_presence_of :project_id, :commit
  validates :results_url, :presence => true, :if => :completed?
  
  default_scope order("completed_at DESC")
  
  serialize :tests
  serialize :coverage
  
  
  
  class << self
    def find_by_commit(sha)
      where(["commit LIKE ?", "#{sha}%"]).first
    end
    
    def excluding(*test_runs_or_ids)
      ids = test_runs_or_ids.flatten.map { |test_run_or_id| test_run_or_id.respond_to?(:id) ? test_run_or_id.id : test_run_or_id }
      where arel_table[:id].not_in(ids)
    end
    
    def completed
      where arel_table[:completed_at].not_eq(nil)
    end
    
    def passed
      where(result: "pass")
    end
    
    def failed
      where(result: "fail")
    end
  end
  
  
  
  def failed?
    result.to_s == "fail"
  end
  
  def passed?
    result.to_s == "pass"
  end
  
  def broken?
    return false unless failed?
    
    last_tested_ancestor = commits_since_last_test_run.last
    return false if last_tested_ancestor.nil?
    
    project.test_runs.find_by_commit(last_tested_ancestor.sha).passed?
  end
  
  def fixed?
    return false unless passed?
    
    last_tested_ancestor = commits_since_last_test_run.last
    return false if last_tested_ancestor.nil?
    
    project.test_runs.find_by_commit(last_tested_ancestor.sha).failed?
  end
  
  
  
  def commits_since_last_test_run
    shas_of_tested_commits = project.test_runs.excluding(self).pluck(:commit)
    project.repo.ancestors_until(commit, :including_self) { |ancestor| shas_of_tested_commits.member?(ancestor.sha) }
  rescue Houston::Adapters::VersionControl::CommitNotFound
    []
  end
  
  def commits_since_last_passing_test_run
    shas_of_passing_commits = project.test_runs.passed.pluck(:commit)
    project.repo.ancestors_until(commit, :including_self) { |ancestor| shas_of_passing_commits.member?(ancestor.sha) }
  rescue Houston::Adapters::VersionControl::CommitNotFound
    []
  end
  alias :blamable_commits :commits_since_last_passing_test_run
  
  
  
  def start!
    trigger_build!
    save!
  end
  
  def short_commit
    commit[0...7]
  end
  
  def completed?
    completed_at.present?
  end
  
  def has_results?
    result.present?
  end
  
  def trigger_build!
    project.ci_server.build!(commit)
  end
  
  def completed!(results_url)
    self.completed_at = Time.now unless completed?
    self.results_url = results_url
    save!
    fetch_results! unless has_results?
  end
  
  def fetch_results!
    attributes = project.ci_server.fetch_results!(results_url)
    update_attributes! attributes
    Houston.observer.fire "test_run:complete", self if has_results?
  end
  
  
  
end

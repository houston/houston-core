class TestRun < ActiveRecord::Base
  
  belongs_to :project
  
  validates_presence_of :project_id, :sha
  validates :results_url, :presence => true, :if => :completed?
  
  default_scope order("completed_at DESC")
  
  serialize :tests
  serialize :coverage
  
  
  
  class << self
    def find_by_sha(sha)
      where(["sha LIKE ?", "#{sha}%"]).first
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
  
  def aborted?
    result.to_s == "aborted"
  end
  
  def broken?
    return false unless failed?
    
    last_tested_ancestor = commits_since_last_test_run.last
    return false if last_tested_ancestor.nil?
    
    project.test_runs.find_by_sha(last_tested_ancestor.sha).passed?
  end
  
  def fixed?
    return false unless passed?
    
    last_tested_ancestor = commits_since_last_test_run.last
    return false if last_tested_ancestor.nil?
    
    project.test_runs.find_by_sha(last_tested_ancestor.sha).failed?
  end
  
  
  
  def commit
    @commit ||= project.find_commit_by_sha(sha)
  end
  
  def coverage_detail
    @coverage_detail ||= (Array(coverage).map do |file|
      file = file.with_indifferent_access
      SourceFileCoverage.new(project, sha, file[:filename], file[:coverage])
    end).select { |file| file.src.any? }
  end
  
  
  
  def commits_since_last_test_run
    shas_of_tested_commits = project.test_runs.excluding(self).pluck(:sha)
    project.repo.ancestors_until(sha, :including_self) { |ancestor| shas_of_tested_commits.member?(ancestor.sha) }
  rescue Houston::Adapters::VersionControl::CommitNotFound
    []
  end
  
  def commits_since_last_passing_test_run
    shas_of_passing_commits = project.test_runs.passed.pluck(:sha)
    project.repo.ancestors_until(sha, :including_self) { |ancestor| shas_of_passing_commits.member?(ancestor.sha) }
  rescue Houston::Adapters::VersionControl::CommitNotFound
    []
  end
  alias :blamable_commits :commits_since_last_passing_test_run
  
  
  
  def retry!
    trigger_build!
  end
  
  def start!
    trigger_build!
    save!
  end
  
  def short_commit
    sha[0...7]
  end
  
  def completed?
    completed_at.present?
  end
  
  def has_results?
    result.present? and !aborted?
  end
  
  def trigger_build!
    project.ci_server.build!(sha)
    Houston.observer.fire "test_run:start", self
  end
  
  def completed!(results_url)
    self.completed_at = Time.now unless completed?
    self.results_url = results_url
    save!
    fetch_results!
  end
  
  def fetch_results!
    attributes = project.ci_server.fetch_results!(results_url)
    update_attributes! attributes
    fire_complete! if has_results?
  end
  
  def fire_complete!
    Houston.observer.fire "test_run:complete", self
  end
  
  
  
  def real_fail_count
    fail_count + regression_count
  end
  
end

class TestRun < ActiveRecord::Base
  include BelongsToCommit
  
  belongs_to :project
  belongs_to :user
  
  validates_presence_of :project_id, :sha
  validates :results_url, :presence => true, :if => :completed?
  validates :result, inclusion: {in: %w{aborted pass fail error}, allow_nil: true, message: "\"%{value}\" is unknown. It must be pass, fail, error, or aborted"}
  
  default_scope { order("completed_at DESC") }
  
  before_save :identify_user
  
  serialize :tests
  serialize :coverage
  
  
  
  class << self
    def find_by_sha(sha)
      return nil if sha.blank?
      where(["sha LIKE ?", "#{sha}%"]).limit(1).first
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
    
    def errored
      where(result: "error")
    end
    
    def most_recent
      joins <<-SQL
        INNER JOIN (
          SELECT project_id, MAX(completed_at) AS completed_at
          FROM test_runs
          GROUP BY project_id
        ) AS most_recent_test_runs
        ON test_runs.project_id=most_recent_test_runs.project_id
        AND test_runs.completed_at=most_recent_test_runs.completed_at
      SQL
    end
  end
  
  
  
  def failed?
    result.to_s == "fail"
  end
  
  def failed_or_errored?
    %w{fail error}.member?(result.to_s)
  end
  
  def passed?
    result.to_s == "pass"
  end
  
  def aborted?
    result.to_s == "aborted"
  end
  
  def broken?
    return false unless failed_or_errored?
    
    last_tested_ancestor = commits_since_last_test_run.last
    return false if last_tested_ancestor.nil?
    
    project.test_runs.find_by_sha(last_tested_ancestor.sha).passed?
  end
  
  def fixed?
    return false unless passed?
    
    last_tested_ancestor = commits_since_last_test_run.last
    return false if last_tested_ancestor.nil?
    
    project.test_runs.find_by_sha(last_tested_ancestor.sha).failed_or_errored?
  end
  
  
  
  def coverage_detail
    @coverage_detail ||= (Array(coverage).map do |file|
      file = file.with_indifferent_access
      SourceFileCoverage.new(project, sha, file[:filename], file[:coverage])
    end).select { |file| file.src.any? }
  end
  
  
  
  def commits_since_last_test_run
    shas_of_tested_commits = project.test_runs.excluding(self).pluck(:sha)
    project.repo.ancestors_until(sha, including_self: true) { |ancestor|
      shas_of_tested_commits.member?(ancestor.sha) }
  rescue Houston::Adapters::VersionControl::CommitNotFound
    []
  end
  
  def commits_since_last_passing_test_run
    shas_of_passing_commits = project.test_runs.passed.pluck(:sha)
    project.repo.ancestors_until(sha, including_self: true) { |ancestor|
      shas_of_passing_commits.member?(ancestor.sha) }
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
    fire_complete! if has_results?
  end
  
  def fetch_results!
    update_attributes! project.ci_server.fetch_results!(results_url)
  rescue Houston::Adapters::CIServer::Error
    update_column :result, "error"
    Rails.logger.error "#{$!.message}\n  #{$!.backtrace.join("\n  ")}"
  end
  
  def fire_complete!
    Houston.observer.fire "test_run:complete", self
  end
  
  
  
  def real_fail_count
    fail_count + regression_count
  end
  
  
  
  def identify_user
    email = Mail::Address.new(agent_email)
    self.user = User.find_by_email_address(email.address)
  end
  
end

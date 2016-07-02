class TestRun < ActiveRecord::Base
  include BelongsToCommit

  belongs_to :project
  belongs_to :user
  has_many :test_results do
    def [](suite, name=nil)
      return super(suite) unless name
      joins(:test).where("tests.suite" => suite, "tests.name" => name).first
    end
  end

  validates :project, presence: true
  validates :sha, presence: true, uniqueness: true
  validates :results_url, :presence => true, :if => :completed?
  validates :result, inclusion: {in: %w{aborted pass fail error}, allow_nil: true, message: "\"%{value}\" is unknown. It must be pass, fail, error, or aborted"}
  validates_associated :test_results

  default_scope { order("completed_at DESC") }

  after_save :save_tests_and_results, if: :tests_changed?
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

    def pending
      where completed_at: nil
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

    def rebuild_tests!(options={})
      test_runs = where("tests is not null")
                 .where("id NOT IN (SELECT DISTINCT test_run_id FROM test_results)")
      if options[:progress]
        require "progressbar"
        pbar = ProgressBar.new("test runs", test_runs.count)
      end
      test_runs.find_each do |test_run|
        if test_run.read_attribute(:tests).nil?
          test_run.update_column :tests, nil
        else
          test_run.save_tests_and_results
        end
        pbar.inc if options[:progress]
      end
      pbar.finish if options[:progress]
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

  def completed_without_running_tests?
    %w{aborted error}.member?(result.to_s)
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

  def short_description(with_duration: false)
    passes = "#{pass_count} #{pass_count == 1 ? "test" : "tests"} passed"
    fails = "#{fail_count} #{fail_count == 1 ? "test" : "tests"} failed"
    duration = " in #{(self.duration / 1000.0).round(1)} seconds" if self.duration && with_duration

    if !completed?
      "#{project.ci_server_name} is running the tests"
    elsif passed?
      "#{passes}#{duration}"
    elsif failed?
      "#{passes} and #{fails}#{duration}"
    elsif aborted?
      "The test run was canceled"
    else
      "#{project.ci_server_name} was not able to run the tests"
    end
  end



  def url
    "https://#{Houston.config.host}/test_runs/#{sha}"
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
    # Let's _not_ trigger the build if this Test Run is not going
    # to be saved. Let's also run BelongsToCommit#identify_commit
    # outside of the transaction that save! wraps it in — so that
    # we can recover from race conditions when creating commits.
    validate!
    trigger_build!
    save!
  end

  def short_commit
    sha[0...7]
  end

  def completed?
    completed_at.present?
  end

  def pending?
    !completed?
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

    if has_results?
      compare_results!
      fire_complete!
    end
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



  def tests=(value)
    @tests = nil
    write_attribute :tests, value
  end

  def failing_tests
    tests.select { |test| test[:status] == "fail" }
  end

  def tests
    @tests ||= test_results.includes(:error).joins(:test).select("test_results.*", "tests.suite", "tests.name").map do |test_result|
      message, backtrace = test_result.error.output.split("\n\n") if test_result.error
      { test_id: test_result.test_id,
        suite: test_result[:suite],
        name: test_result[:name].to_s.gsub(/^(test :|: )/, ""),
        status: test_result.status,
        duration: test_result.duration,
        error_message: message,
        error_backtrace: backtrace.to_s.split("\n") }
    end
  end



  def real_fail_count
    fail_count + regression_count
  end



  def identify_user
    email = Mail::Address.new(agent_email)
    self.user = User.find_by_email_address(email.address)
  end

  def save_tests_and_results
    create_tests_and_results read_attribute(:tests)
  end

  def create_tests_and_results(tests)
    tests = Array(tests)
    return if tests.empty?

    tests_map = Hash.new do |hash, (suite, name)|
      begin
        test = Test.create!(suite: suite, name: name, project_id: project_id)
      rescue ActiveRecord::RecordNotUnique
        test = Tests.find_by(suite: suite, name: name, project_id: project_id)
      end
      hash[[suite, name]] = test.id
    end

    Test.where(project_id: project_id).pluck(:suite, :name, :id).each do |suite, name, id|
      tests_map[[suite, name]] = id
    end

    errors_map = Hash[TestError.pluck(:sha, :id)]

    test_results = Houston.benchmark("Processing #{tests.count} test results") do
      tests.map do |test_attributes|
        suite = test_attributes.fetch :suite
        name = test_attributes.fetch :name

        status = test_attributes.fetch :status
        status = :fail if status == :error or status == :regression

        error_message = test_attributes[:error_message]
        error_backtrace = (test_attributes[:error_backtrace] || []).join("\n")
        output = [error_message, error_backtrace].reject(&:blank?).join("\n\n")
        if output.blank?
          error_id = nil
        else
          sha = Digest::SHA1.hexdigest(output)
          error_id = errors_map[sha]
          unless error_id
           error = TestError.create!(output: output)
           error_id = errors_map[error.sha] = error.id
          end
        end

        { test_run_id: id,
          test_id: tests_map[[suite, name]],
          error_id: output.blank? ? nil : output,
          status: status,
          error_id: error_id,
          duration: test_attributes.fetch(:duration, nil) }
      end.uniq { |attributes| attributes[:test_id] }
    end

    TestResult.where(test_run_id: id).delete_all
    Houston.benchmark("Inserting #{test_results.count} test results") do
      TestResult.insert_many(test_results)
    end
  end



  def compare_results!
    return if completed_without_running_tests?
    return unless commit
    compare_to_parent!
    compare_to_children!
  end

  def compare_to_parent!
    return if compared?
    return unless parent = commit.parent

    if parent.test_run
      if parent.test_run.completed?
        # Compare this Test Run with its parent
        # to see what changed in this one.
        TestRunComparer.compare!(parent.test_run, self)
        parent.test_run.compare_results!
      else
        # Wait for parent.test_run to complete
        # it'll run `compare_results!` then.
        # For now, do nothing.
      end
    else
      if passed?
        # Stop looking for answers. This Test Run
        # is the new baseline: when the whole suite
        # was building on Jenkins. (We don't need to
        # recurse all the way back to the project's
        # first commit!)
      else
        # This Test Run is failing and we don't
        # know whether the bug was introduced in this
        # commit or one of its ancestors. Have the
        # CI Server start with the first ancestor.
        parent.create_test_run!
      end
    end
  end

  def compare_to_children!
    commit.children.each do |commit|
      commit.test_run.compare_results! if commit.test_run
    end
  end

private

  # This is defined in Rails 4.2 but absent in previous versions
  def validate!
    raise ActiveRecord::RecordInvalid.new(self) unless valid?
  end

end

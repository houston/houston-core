class RunTestsOnPostReceive
  
  def self.instance
    @instance ||= self.new
  end
  
  def self.begin!
    instance.begin!
  end
  
  def begin!
    # Here's how this works:
    #
    #   1. GitHub receives a `git push` and triggers all Web Hooks:
    #      POST /projects/houston/hooks/post_receive.
    #   2. Houston receives this request and fires the
    #      'hooks:post_receive' event.
    #   3. Houston creates a TestRun and tells a CI server to build
    #      then corresponding job:
    #      POST /job/houston/buildWithParameters.
    Houston.observer.on "hooks:post_receive", &method(:create_a_test_run)
    
    #   4. Houston notifies GitHub that the test run has started:
    #      POST /repos/houstonmc/houston/statuses/:sha
    Houston.observer.on "test_run:start", &method(:publish_status_to_github)
    
    #   5. Jenkins checks out the project, runs the tests, and
    #      tells Houston that it is finished:
    #      POST /projects/houston/hooks/post_build.
    #   6. Houston receives the request and fires the
    #      'hooks:post_build' event.
    #   7. Houston updates the TestRun,
    #      fetching additional details from Jenkins:
    #      GET /job/houston/19/testReport/api/json
    Houston.observer.on "hooks:post_build", &method(:fetch_test_run_results)
    
    #   8. Houston emails results of the TestRun.
    Houston.observer.on "test_run:complete", &method(:email_test_run_results)
    
    #   9. Houston publishes results to GitHub:
    #      POST /repos/houstonmc/houston/statuses/:sha
    Houston.observer.on "test_run:complete", &method(:publish_status_to_github)
    
    #  10. Houston publishes results to Code Climate.
    Houston.observer.on "test_run:complete", &method(:publish_coverage_to_code_climate)
  end
  
  
  
  def create_a_test_run(project, params)
    unless project.has_ci_server?
      Rails.logger.warn "[hooks:post_receive] the project #{project.name} is not configured to be used with a Continuous Integration server"
      return
    end
    
    payload = PostReceivePayload.new(params)
    
    unless payload.commit
      Rails.logger.error "[hooks:post_receive] no commit found in payload"
      return
    end
    
    test_run = project.test_runs.find_by_sha(payload.commit)
    
    if test_run
      Rails.logger.warn "[hooks:post_receive] a test run exists for #{test_run.short_commit}; doing nothing"
      return
    end
    
    test_run = TestRun.new(
      project: project,
      sha: payload.commit,
      agent_email: payload.agent_email,
      branch: payload.branch)
    
    notify_of_invalid_configuration(test_run) do
      test_run.start!
    end
  end
  
  
  def fetch_test_run_results(project, params)
    commit, results_url = params.values_at(:commit, :results_url)
    test_run = project.test_runs.find_by_sha(commit)
    
    unless test_run
      Rails.logger.warn "[hooks:post_build] no test run found for project '#{project.slug}' and commit '#{commit}'"
      return
    end
    
    if results_url.blank?
      message = "#{project.ci_server_name} is not appropriately configured to build #{project.name}."
      additional_info = "#{project.ci_server_name} did not supply 'results_url' when it triggered the post_build hook"
      ProjectNotification.ci_configuration_error(test_run, message, additional_info: additional_info).deliver!
      return
    end
    
    notify_of_invalid_configuration(test_run) do
      test_run.completed!(results_url)
    end
  end
  
  
  def email_test_run_results(test_run)
    ProjectNotification.test_results(test_run).deliver!
  end
  
  
  
  # http://developer.github.com/v3/repos/statuses/#create-a-status
  # status is [pending, success, error, failure]
  # RunTestsOnPostReceive.instance.publish_status_to_github(tr)
  def publish_status_to_github(test_run)
    project = test_run.project
    return unless project.repo.respond_to? :commit_status_url
      
    access_token = Houston.config.github[:access_token]
    unless access_token
      message = "Houston can publish your test results to GitHub"
      additional_info = "Supply github/access_token in Houston's config.rb"
      ProjectNotification.ci_configuration_error(test_run, message, additional_info: additional_info).deliver!
      return
    end
    
    github_status_url = project.repo.commit_status_url(test_run.sha)
    if test_run.completed?
      status = {"pass" => "success", "fail" => "failure"}.fetch(test_run.result, "error")
    else
      status = "pending"
    end
    
    Rails.logger.info "[test_run:complete] POST #{status} to #{github_status_url}"
    github_status_url << "?access_token=#{access_token}"
    response = Faraday.post(github_status_url, JSON.dump({
      state: status,
      target_url: test_run.results_url
    }))
    
    unless response.success?
      message = "Houston was unable to publish your test results to GitHub"
      additional_info = "GitHub returned #{response.status}: #{response.body}"
      ProjectNotification.ci_configuration_error(test_run, message, additional_info: additional_info).deliver!
    end
    
    response
  end
  
  
  
  def publish_coverage_to_code_climate(test_run)
    return if test_run.project.code_climate_repo_token.blank?
    CodeClimate::CoverageReport.publish!(test_run)
  rescue
    message = "Houston was unable to publish your code coverage to Code Climate"
    ProjectNotification.ci_configuration_error(test_run, message, additional_info: $!.message).deliver!
  end
  
  
  
private
  
  def notify_of_invalid_configuration(test_run)
    begin
      yield
    rescue Houston::Adapters::CIServer::Error
      project = test_run.project
      message = "#{project.ci_server_name} is not appropriately configured to build #{project.name}."
      ProjectNotification.ci_configuration_error(test_run, message, additional_info: $!.message).deliver!
    end
  end
  
end



class PostReceivePayload
  
  def initialize(params)
    parse_params(params)
  end
  
  attr_accessor :agent_email, :commit, :branch
  
  def parsed?
    commit.present?
  end
  
  def parse_params(params)
    json_payload = params.key?("payload") && JSON.parse(params["payload"]) rescue nil
    parse_github_style_params(json_payload) if json_payload
  end
  
  def parse_github_style_params(params)
    self.commit = params["after"]
    self.agent_email = parse_github_style_agent(params["pusher"])
    self.branch = params["ref"].split("/").last if params.key?("ref")
  end
  
  def parse_github_style_agent(params)
    return nil unless params.key?("email")
    return params["email"] unless params.key?("name")
    "#{params["name"].inspect} <#{params["email"]}>"
  end
  
end



RunTestsOnPostReceive.begin!

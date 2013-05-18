class RunTestsOnPostReceive
  
  def self.begin!
    self.new.begin!
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
    
    #   4. Jenkins checks out the project, runs the tests, and
    #      tells Houston that it is finished:
    #      POST /projects/houston/hooks/post_build.
    #   5. Houston receives the request and fires the
    #      'hooks:post_build' event.
    #   6. Houston updates the TestRun,
    #      fetching additional details from Jenkins:
    #      GET /job/houston/19/testReport/api/json
    Houston.observer.on "hooks:post_build", &method(:fetch_test_run_results)
    
    #   7. Houston emails results of the TestRun.
    Houston.observer.on "test_run:complete", &method(:email_test_run_results)
    
    #   8. Houston publishes results to GitHub:
    #      POST /repos/houstonmc/houston/statuses/:sha
    Houston.observer.on "test_run:complete", &method(:publish_results_to_github)
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
    
    test_run = project.test_runs.find_by_commit(payload.commit)
    
    if test_run
      Rails.logger.warn "[hooks:post_receive] a test run exists for #{test_run.short_commit}; doing nothing"
      return
    end
    
    notify_of_invalid_configuration(project) do
      TestRun.new(
        project: project,
        commit: payload.commit,
        agent_email: payload.agent_email,
        branch: payload.branch).start!
    end
  end
  
  
  def fetch_test_run_results(project, params)
    commit, results_url = params.values_at(:commit, :results_url)
    test_run = project.test_runs.find_by_commit(commit)
    
    unless test_run
      Rails.logger.warn "[hooks:post_build] no test run found for project '#{project.slug}' and commit '#{commit}'"
      return
    end
    
    if results_url.blank?
      message = "#{project.ci_server_name} is not appropriately configured to build #{project.name}."
      additional_info = "#{project.ci_server_name} did not supply 'results_url' when it triggered the post_build hook"
      ProjectNotification.configuration_error(project, message, additional_info: additional_info).deliver!
      return
    end
    
    notify_of_invalid_configuration(project) do
      test_run.completed!(results_url)
    end
  end
  
  
  def email_test_run_results(test_run)
    ProjectNotification.test_results(test_run).deliver!
  end
  
  
  def publish_results_to_github(test_run)
    project = test_run.project
    
    unless project.version_control_name == "Git"
      Rails.logger.warn "[test_run:complete] #{project.slug} does not use git"
      return
    end
    
    unless project.repo.github?
      Rails.logger.warn "[test_run:complete] #{project.slug} is not at GitHub"
      return
    end
    
    # http://developer.github.com/v3/repos/statuses/#create-a-status
    path = Addressable::URI.parse(project.repo.location).path[0...-4]
    github_status_url = "https://api.github.com/#{path}/statuses/#{test_run.commit}"
    Rails.logger.info "[test_run:complete] POST #{github_status_url}"
    Faraday.post(github_status_url, {
      status: test_run.result,
      target_url: test_run.results_url
    })
  end
  
private
  
  def notify_of_invalid_configuration(project)
    begin
      yield
    rescue Houston::Adapters::CIServer::Error
      message = "#{project.ci_server_name} is not appropriately configured to build #{project.name}."
      ProjectNotification.configuration_error(project, message, additional_info: $!.message).deliver!
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

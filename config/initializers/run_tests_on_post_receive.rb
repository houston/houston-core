#
# Here's an example of how this works:
#
#   1. GitHub receives a `git push` and triggers all Web Hooks:
#      POST /projects/houston/hooks/post_receive.
#   2. Houston receives the request and fires the
#      'hooks:post_receive' event.
#   3. Houston, on 'hooks:post_receive', creates a TestRun
#      and tells Jenkins to build the corresponding job:
#      POST /job/houston/buildWithParameters.
#   4. Jenkins checks out the project, runs the tests, and
#      tells Houston that it is finished:
#      POST /projects/houston/hooks/post_build.
#   5. Houston receives the request and fires the
#      'hooks:post_build' event.
#   6. Houston, on 'hooks:post_build', updates the TestRun,
#      fetching additional details from Jenkins:
#      GET /job/houston/19/testReport/api/json
#   7. Houston emails results of the TestRun.
#   8. Houston publishes results to GitHub:
#      POST /repos/houstonmc/houston/statuses/:sha
#   9. Houston automatically deploys the project if the
#      tests passed and the push was to dev or master.
#

module PostReceiveHook
  
  GITHUB_WEBHOOK_IPS = %w{207.97.227.253
                          50.57.128.197
                          108.171.174.178
                          50.57.231.61
                          54.235.183.49
                          54.235.183.23
                          54.235.118.251
                          54.235.120.57
                          54.235.120.61
                          54.235.120.62}
  
  def self.commit_from_payload(params)
    ip = params.fetch(:sender, {})[:ip]
    case ip
    when *GITHUB_WEBHOOK_IPS
      payload = JSON.parse params["payload"]
      payload["after"]
    else
      Rails.logger.warn "[post-receive-hook] did not recognize remote IP: '#{ip}'"
      nil
    end
  end
  
end



# 3. Houston creates a Test Run.
Houston.observer.on "hooks:post_receive" do |project, payload|
  
  if project.ci_adapter == "None"
    Rails.logger.warn "[hooks:post_receive] the project #{project.name} is not configured to be used with a Continuous Integration server"
    next
  end
  
  commit = PostReceiveHook.commit_from_payload(payload)
  
  unless commit
    Rails.logger.error "[hooks:post_receive] no commit found in payload"
    next
  end
  
  test_run = project.test_runs.find_by_commit(commit)
  
  if test_run
    Rails.logger.warn "[hooks:post_receive] a test run exists for #{test_run.short_commit}; doing nothing"
    next
  end
  
  begin
    TestRun.new(project: project, commit: commit).start!
  rescue Houston::CI::Error
    message = "#{project.ci_adapter} is not appropriately configured to build #{project.name}."
    ProjectNotification.configuration_error(project, message, additional_info: $!.message).deliver!
  end
end



# 6. Houston updates the Test Run.
Houston.observer.on "hooks:post_build" do |project, params|
  commit, results_url = params.values_at(:commit, :results_url)
  test_run = project.test_runs.find_by_commit(commit)
  
  unless test_run
    Rails.logger.warn "[hooks:post_build] no test run found for project '#{project.slug}' and commit '#{commit}'"
    next
  end
  
  if results_url.blank?
    message = "#{project.ci_adapter} is not appropriately configured to build #{project.name}."
    additional_info = "#{project.ci_adapter} did not supply 'results_url' when it triggered the post_build hook"
    ProjectNotification.configuration_error(project, message, additional_info: additional_info).deliver!
    next
  end
  
  begin
    test_run.completed!(results_url)
  rescue Houston::CI::Error
    message = "#{project.ci_adapter} is not appropriately configured to build #{project.name}."
    ProjectNotification.configuration_error(project, message, additional_info: $!.message).deliver!
  end
end



# 7. Houston emails results.
Houston.observer.on "test_run:complete" do |test_run|
  ProjectNotification.test_results(test_run).deliver!
end



# 8. Houston publishes results to GitHub
Houston.observer.on "test_run:complete" do |test_run|
  project = test_run.project
  
  unless project.version_control_adapter == "Git"
    Rails.logger.warn "[test_run:complete] #{project.slug} does not use git"
    next
  end
  
  unless project.version_control_location =~ /github/
    Rails.logger.warn "[test_run:complete] #{project.slug} is not at GitHub"
    next
  end
  
  # http://developer.github.com/v3/repos/statuses/#create-a-status
  path = Addressable::URI.parse(project.version_control_location).path[0...-4]
  github_status_url = "https://api.github.com/#{path}/statuses/#{test_run.commit}"
  Rails.logger.info "[test_run:complete] POST #{github_status_url}"
  Faraday.post(github_status_url, {
    status: test_run.result,
    target_url: test_run.results_url
  })
end



# 9. Houston automatically deploys the project
Houston.observer.on "test_run:complete" do |test_run|
  project = test_run.project
  branches = project.repo.branches_at(test_run.commit)
  
  Rails.logger.info "[test_run:complete] Ran tests for #{test_run.short_commit}; branches at #{test_run.short_commit}: [#{branches.join(", ")}]"
  
  # if branches.member?("master")
  #   Rails.logger.warn "[test_run:complete] DEPLOY TO PRODUCTION"
  #   # binding.pry
  # end
  # 
  # if branches.member?("dev")
  #   Rails.logger.warn "[test_run:complete] DEPLOY TO STAGING"
  #   # binding.pry
  # end
end

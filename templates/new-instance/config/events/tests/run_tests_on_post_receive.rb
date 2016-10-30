Houston.config do
  # Here's how this works:
  #
  #   1. GitHub receives a `git push` and triggers all Web Hooks:
  #      POST /projects/houston/hooks/post_receive.
  #   2. Houston receives this request and fires the
  #      'hooks:project:post_receive' event.
  #   3. Houston creates a TestRun and tells a CI server to build
  #      then corresponding job:
  #      POST /job/houston/buildWithParameters.
  on "hooks:project:post_receive" => "run-tests-on-post-receive" do
    project.create_a_test_run(params)
  end

  #   4. Houston notifies GitHub that the test run has started:
  #      POST /repos/houston/houston/statuses/:sha
  action "test-run:publish-status-to-github", ["test_run"] do
    test_run.publish_status_to_github
  end
  on "test_run:start" => "test-run:publish-status-to-github"

  #   5. Jenkins checks out the project, runs the tests, and
  #      tells Houston that it is finished:
  #      POST /projects/houston/hooks/post_build.
  #   6. Houston receives the request and fires the
  #      'hooks:post_build' event.
  #   7. Houston updates the TestRun,
  #      fetching additional details from Jenkins:
  #      GET /job/houston/19/testReport/api/json
  on "hooks:post_build" => "fetch-results-on-post-build" do
    commit, results_url = params.values_at(:commit, :results_url)
    test_run = project.test_runs.find_or_create_by_sha(commit)
    test_run.notify_of_invalid_configuration do
      test_run.completed!(results_url)
    end
  end

  #   8. Houston publishes results to GitHub:
  #      POST /repos/houston/houston/statuses/:sha
  on "test_run:complete" => "test-run:publish-status-to-github"

  #   9. Houston publishes results to Code Climate.
  on "test_run:complete" => "test-run:publish-coverage-to-codeclimate" do
    begin
      return if test_run.project.code_climate_repo_token.blank?
      CodeClimate::CoverageReport.publish!(test_run)
    rescue Houston::Adapters::VersionControl::CommitNotFound
      # Got a bad Test Run, nothing we can do about it.
    rescue CodeClimate::ServerError
      # Error on Code Climate's end
    end
  end

end

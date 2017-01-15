Houston.config do
  on "test_run:complete" => "test_run:email-results" do
    project = test_run.project
    committers = test_run.commits_since_last_test_run.map { |commit| commit.author_email.downcase }
    recipients = (committers + Array(test_run.agent_email)).uniq \
               - project.maintainers.map(&:email) \
               + project.maintainers

    Houston.deliver! Houston::Ci::Mailer.test_results(test_run, recipients)
  end
end

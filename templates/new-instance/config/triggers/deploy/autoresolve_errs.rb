Houston.config.on "alert:err:deployed" do |alert, deploy, commit|
  error_tracker = deploy.project.error_tracker

  message = "Resolved by Houston when "
  message << (commit.url ? "[#{commit.sha[0...7]}](#{commit.url})" : commit.sha[0...7])
  message << " was [deployed to #{deploy.environment_name}](#{deploy.url})"

  Houston.try({max_tries: 3, ignore: true}, Faraday::Error::TimeoutError) do
    error_tracker.resolve! alert.number, message: message
  end
end

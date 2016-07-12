Houston.config.on "alert:err:deployed" do |e|
  error_tracker = e.deploy.project.error_tracker

  message = "Resolved by Houston when "
  message << (e.commit.url ? "[#{e.commit.sha[0...7]}](#{e.commit.url})" : e.commit.sha[0...7])
  message << " was [deployed to #{e.deploy.environment_name}](#{e.deploy.url})"

  Houston.try({max_tries: 3, ignore: true}, Faraday::Error::TimeoutError) do
    error_tracker.resolve! e.alert.number, message: message
  end
end

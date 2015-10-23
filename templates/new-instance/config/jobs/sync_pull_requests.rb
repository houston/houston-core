Houston.config.every "10m", "sync:pulls" do
  Github::PullRequest.sync!
end

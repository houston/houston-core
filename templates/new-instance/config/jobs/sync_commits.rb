Houston.config.at "2:00am", "sync:commits" do
  SyncCommitsJob.run!
end

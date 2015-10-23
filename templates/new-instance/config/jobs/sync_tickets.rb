Houston.config.every "6h", "sync:tickets" do
  SyncAllTicketsJob.run!
end

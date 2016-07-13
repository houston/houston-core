Houston.config.at "10:00pm", "purge:jobs" do
  Job.started_before(1.week.ago).delete_all
end

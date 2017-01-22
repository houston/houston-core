Houston.config.every "day at 10:00pm", "purge:jobs" do
  Action.started_before(1.week.ago).delete_all
end

Houston.config do
  on "daemon:scheduler:restart" do
    slack_send_message_to "The thread running Rufus::Scheduler errored out and is attempting to recover", "general"
  end

  on "daemon:scheduler:stop" do
    slack_send_message_to ":rotating_light: The thread running Rufus::Scheduler has terminated", "general"
  end

  on "daemon:slack:restart" do
    slack_send_message_to "The thread running Slack errored out and is attempting to recover", "general"
  end

  on "daemon:slack:stop" do
    slack_send_message_to ":rotating_light: The thread running Slack has terminated", "general"
  end

  on "slack:error" do |e|
    slack_send_message_to "An error occurred\n#{e.message}", "general"
  end
end

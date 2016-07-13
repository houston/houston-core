Houston.config do
  on "daemon:scheduler:restart" => "daemon:announce-scheduler-restarted-in-slack" do
    slack_send_message_to "The thread running Rufus::Scheduler errored out and is attempting to recover", "general"
  end

  on "daemon:scheduler:stop" => "daemon:announce-scheduler-stopped-in-slack" do
    slack_send_message_to ":rotating_light: The thread running Rufus::Scheduler has terminated", "general"
  end

  on "daemon:slack:restart" => "daemon:announce-slack-restarted-in-slack" do
    slack_send_message_to "The thread running Slack errored out and is attempting to recover", "general"
  end

  on "daemon:slack:stop" => "daemon:announce-slack-stopped-in-slack" do
    slack_send_message_to ":rotating_light: The thread running Slack has terminated", "general"
  end

  on "slack:error" => "slack:announce-error-in-slack" do
    slack_send_message_to "An error occurred\n#{message}", "general"
  end
end

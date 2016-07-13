Houston.config do
  # Notify #alerts of new alerts
  on "alert:create" => "alert:announce-in-slack" do
    message =  "There's a new *#{alert.type}*"
    message << " for #{alert.project.slug}" if alert.project
    slack_send_message_to message, "#alerts", attachments: [slack_alert_attachment(alert)]
  end
end

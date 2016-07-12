Houston.config do
  # Notify #alerts of new alerts
  on "alert:create" do |e|
    message =  "There's a new *#{e.alert.type}*"
    message << " for #{e.alert.project.slug}" if e.alert.project
    slack_send_message_to message, "#alerts", attachments: [slack_alert_attachment(e.alert)]
  end
end

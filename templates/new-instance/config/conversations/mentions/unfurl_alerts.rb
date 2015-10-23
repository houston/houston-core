Houston::Slack.config do
  overhear(/cve[\s:](?<number>\d+)\b/i) do |e|
    alert = Houston::Alerts::Alert.where(type: "cve", number: e.match[:number]).first
    e.unfurl slack_alert_attachment(alert)
  end

  overhear(/(?:err|exception)[\s:](?<number>\d+)\b/i) do |e|
    alert = Houston::Alerts::Alert.where(type: "err", number: e.match[:number]).first
    e.unfurl slack_alert_attachment(alert)
  end

  overhear(/alert (?<number>\d+)\b/i) do |e|
    Houston::Alerts::Alert.where(number: e.match[:number]).each do |alert|
      e.unfurl slack_alert_attachment(alert)
    end
  end
end

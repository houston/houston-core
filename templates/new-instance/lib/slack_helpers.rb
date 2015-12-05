def slack_send_message_to(message, channel, options={})
  if channel.is_a?(User)
    channel = channel.slack_username

    unless channel
      Rails.logger.info "\e[34m[slack:say] I don't know the Slack username for #{channel.email}\e[0m"
      return
    end
  end

  if options.delete(:as) == :github
    options.merge!(
      as_user: false,
      username: "github",
      icon_url: "https://slack.global.ssl.fastly.net/5721/plugins/github/assets/service_128.png")
  end

  if !Rails.env.development?
    Houston::Slack.send message, options.merge(channel: channel)
  elsif options.delete(:test)
    message = "[#{channel}]\n#{message}" unless channel == "test"
    channel = "test"
    Houston::Slack.send message, options.merge(channel: channel)
  else
    Rails.logger.debug "\e[95m[slack:say] #{channel}: #{message}\e[0m"
  end
end

def slack_alert_attachment(alert, options={})
  title = slack_link_to(alert.summary, alert.url)
  title << " {{#{alert.type}:#{alert.number}}}" if alert.number
  attachment = {
    fallback: "#{slack_escape(alert.summary)} - #{alert.url} - #{alert.number}",
    title: title,
    color: slack_project_color(alert.project) }

  attachment.merge!(text: alert.text) unless alert.text.blank?
  attachment
end

def slack_task_attachment(task, options={})
  # title = slack_link_to(alert.summary, alert.url)
  # title << " {{#{alert.type}:#{alert.number}}}" if alert.number
  { fallback: "#{task.shorthand} - #{task.description}",
    title: "#{task.project.name} task ##{task.shorthand}",
    text: task.description,
    color: slack_project_color(task.project) }
end

def slack_project_color(project)
  "##{project.color_value}" if project
end

def slack_link_to_pull_request(pr)
  url = pr._links ? pr._links.html.href : pr.pull_request.html_url
  slack_link_to "##{pr.number} #{pr.title}", url
end

def slack_link_to(message, url)
  return message unless url
  "<#{url}|#{slack_escape(message)}>"
end

def slack_escape(message)
  message.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "gt;").gsub(/[\r\n]/, " ")
end

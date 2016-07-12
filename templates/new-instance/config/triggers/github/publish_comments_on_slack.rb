Houston.config do
  on "github:comment:created:commit" do |e|
    channel = "##{e.comment["project"].slug}" if e.comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = e.comment.values_at "body", "html_url"

    message = "#{e.comment["user"]["login"]} commented on #{slack_link_to(e.comment["commit_id"][0...7], url)}"

    comment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [comment], test: true
  end

  on "github:comment:created:diff" do |e|
    channel = "##{e.comment["project"].slug}" if e.comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = e.comment.values_at "body", "html_url"

    message = "#{e.comment["user"]["login"]} commented on #{slack_link_to(e.comment["path"], url)}"
    message << "\n```\n#{e.comment["diff_hunk"]}\n```\n"

    comment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [comment], test: true
  end

  on "github:comment:created:pull" do |e|
    channel = "##{e.comment["project"].slug}" if e.comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = e.comment.values_at "body", "html_url"

    issue = e.comment["issue"]
    message = "#{e.comment["user"]["login"]} commented on #{slack_link_to("##{issue["number"]} #{issue["title"]}", url)}"

    comment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [comment], test: true
  end
end

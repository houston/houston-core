Houston.config do
  on "github:comment:commit:create" => "github:slack-when-commit-comment-created" do
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["commit_id"][0...7], url)}"

    attachment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [attachment]
  end

  on "github:comment:diff:create" => "github:slack-when-diff-comment-created" do
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["path"], url)}"
    message << "\n```\n#{comment["diff_hunk"]}\n```\n"

    attachment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [attachment]
  end

  on "github:comment:pull:create" => "github:slack-when-issue-comment-created" do
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    issue = comment["issue"]
    message = "#{comment["user"]["login"]} commented on #{slack_link_to("##{issue["number"]} #{issue["title"]}", url)}"

    attachment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [attachment]
  end
end

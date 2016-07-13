Houston.config do
  on "test_run:complete" do |e|
    # When branch is nil, the test run was requested by Houston
    # not triggered by a developer pushing changes to GitHub.
    next if e.test_run.branch.nil?
    next if e.test_run.aborted?

    nickname = e.test_run.user.slack_username if e.test_run.user
    project_slug = e.test_run.project.slug
    project_channel = "##{project_slug}"
    branch = "#{project_slug}/#{e.test_run.branch}"

    text = e.test_run.short_description(with_duration: true)
    text << "\n#{nickname}" if e.test_run.result != "pass" && nickname

    attachment = case e.test_run.result
    when "pass"
      { color: "#5DB64C",
        title: "All tests passed on #{branch}" }
    when "fail"
      { color: "#E24E32",
        title: "#{e.test_run.fail_count} #{e.test_run.fail_count == 1 ? "test" : "tests"} failed on #{branch}" }
    else
      { color: "#DFCC3D",
        title: "The tests are broken on #{branch}" }
    end
    attachment.merge!(
      title_link: e.test_run.url,
      fallback: attachment[:title],
      text: text)

    channel = project_channel if Houston::Slack.connection.channels.include? project_channel
    channel ||= nickname
    channel ||= "general"

    slack_send_message_to nil, channel, attachments: [attachment]
  end
end

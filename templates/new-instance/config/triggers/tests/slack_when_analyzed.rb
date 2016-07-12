Houston.config do
  on "test_run:compared" do |e|
    regressions = e.test_run.test_results.where(different: true, status: "fail").to_a
    next if regressions.none?

    commit = slack_link_to(e.test_run.sha[0...7], e.test_run.commit.url)
    predicate = "this test:" if regressions.count == 1
    predicate = "these tests:" if regressions.count > 1 && regressions.count < 5
    predicate = "#{regressions.count} tests" if regressions.count > 5
    predicate = slack_link_to(predicate, e.test_run.url)

    message = "Hey... I think this commit :point_right: *#{commit}* broke #{predicate}"

    regressions.each do |regression|
      message << "\n> *#{regression.test.suite}* #{regression.test.name}"
    end if regressions.count < 5

    project_channel = "##{e.test_run.project.slug}"
    channels = [project_channel] if Houston::Slack.connection.channels.include? project_channel
    channels ||= e.test_run.commit.committers.map(&:slack_username)
    channels = %w{general} if Array(channel).empty?

    channels.each do |channel|
      slack_send_message_to message, channel
    end
  end
end

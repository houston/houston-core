Houston.config do
  on "test_run:compared" do |test_run|
    regressions = test_run.test_results.where(different: true, status: "fail").to_a
    next if regressions.none?

    commit = slack_link_to(test_run.sha[0...7], test_run.commit.url)
    predicate = "this test:" if regressions.count == 1
    predicate = "these tests:" if regressions.count > 1 && regressions.count < 5
    predicate = "#{regressions.count} tests" if regressions.count > 5
    predicate = slack_link_to(predicate, test_run.url)

    message = "Hey... I think this commit :point_right: *#{commit}* broke #{predicate}"

    regressions.each do |regression|
      message << "\n> *#{regression.test.suite}* #{regression.test.name}"
    end if regressions.count < 5

    project_channel = "##{test_run.project.slug}"
    channels = [project_channel] if Houston::Slack.connection.channels.include? project_channel
    channels ||= test_run.commit.committers
      .pluck(:email)
      .map { |email| SLACK_USERNAME_FOR_USER[email] }
      .reject(&:nil?)
    channels = %w{general} if Array(channel).empty?

    channels.each do |channel|
      slack_send_message_to message, channel
    end
  end
end

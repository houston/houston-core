class ProjectNotification < ViewMailer
  include ActionView::Helpers::DateHelper
  include TestRunHelper


  def release(release, options={})
    @release = release
    @project = release.project

    mail({
      from:     release.user,
      to:       options.fetch(:to, @release.notification_recipients),
      cc:       options.fetch(:cc, @project.maintainers),
      subject:  "new release to #{release.environment_name}",
      template: "new_release"
    })
  end


  def test_results(test_run, options={})
    @test_run = test_run
    @project = test_run.project

    committers = test_run.commits_since_last_test_run.map { |commit| commit.author_email.downcase }
    recipients = (committers + Array(test_run.agent_email)).uniq \
               - @project.maintainers.map(&:email) \
               + @project.maintainers

    mail({
      to:       recipients,
      subject:  test_run_summary(test_run),
      template: "test_run"
    })
  end


  def testing_note(testing_note, recipients)
    @note = testing_note
    @tester = testing_note.user
    @ticket = testing_note.ticket
    @project = testing_note.project
    @verdict = testing_note.verdict

    case @verdict
    when "fails"
      @verb = "failed"
      @noun = "Failing Verdict"
    when "none"
      @verb = "commented on"
      @noun = "Comment"
    when "works"
      @verb = "passed"
      @noun = "Passing Verdict"
    else
      Rails.logger.warn "[project_notification] Unhandled TestingNote verdict: #{@verdict.inspect}"
      return
    end

    mail({
      from:     @tester,
      to:       recipients - [@tester],
      subject:  "#{@tester.name} #{@verb} ticket ##{@ticket.number}",
      template: "testing_note"
    })
  end


  def maintainer_of_deploy(maintainer, deploy)
    @project = deploy.project
    @release = deploy.build_release
    @maintainer = maintainer

    if @maintainer.respond_to?(:reset_authentication_token!)
      @maintainer.reset_authentication_token!
      @auth_token = @maintainer.authentication_token
    end

    if @release.commits.empty? && @release.can_read_commits?
      @release.load_commits!
      @release.load_tickets!
      @release.build_changes_from_commits
    end

    mail({
      to:       @maintainer,
      subject:  "deploy to #{deploy.environment_name} complete. Click to Release!",
      template: "new_release"
    })
  end


  def ci_configuration_error(test_run, message, options={})
    @test_run = test_run
    @project = test_run.project
    @message = message
    @additional_info = options[:additional_info]

    mail({
      to:       options.fetch(:to, @project.maintainers),
      subject:  "configuration error",
      template: "ci_configuration_error"
    })
  end


  def follow_up(antecedent)
    @antecedent = antecedent
    @ticket = antecedent.ticket
    @project = @ticket.project
    @reporter = antecedent.reporter
    @customer = @antecedent.customer

    mail({
      to: @reporter,
      subject: "Sample Ticket follow-up",
      template: "follow_up"
    })
  end


protected


  def mail(options={})
    options[:subject] = "#{@project.name}: #{options[:subject]}"
    options[:template] = "project_notification/#{options[:template]}" unless options[:template].start_with?("/")
    super
  end


end

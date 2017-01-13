class ProjectNotification < ViewMailer
  include ActionView::Helpers::DateHelper
  include TestRunHelper


  def release(release, options={})
    @release = release
    @project = release.project

    mail({
      from:     release.user,
      to:       options.fetch(:to, @release.notification_recipients),
      subject:  "new release to #{release.environment_name}",
      template: "new_release"
    })
  end


  def test_results(test_run, recipients, options={})
    @test_run = test_run
    @project = test_run.project

    mail({
      to:       recipients,
      subject:  test_run_summary(test_run),
      template: "test_run"
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
      to:       options.fetch(:to, @project.team_owners),
      subject:  "configuration error",
      template: "ci_configuration_error"
    })
  end


protected


  def mail(options={})
    options[:subject] = "#{@project.name}: #{options[:subject]}"
    options[:template] = "project_notification/#{options[:template]}" unless options[:template].start_with?("/")
    super
  end


end

class ProjectNotification < ViewMailer
  include ActionView::Helpers::DateHelper
  include TestRunHelper


  def test_results(test_run, recipients, options={})
    @test_run = test_run
    @project = test_run.project

    mail({
      to:       recipients,
      subject:  test_run_summary(test_run),
      template: "test_run"
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

class ProjectNotification < ViewMailer
  
  
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
    
    mail({
      to:       options.fetch(:to, @project.maintainers),
      subject:  "test results",
      template: "test_run"
    })
  end
  
  
  def failing_verdict(testing_note, options={})
    @note = testing_note
    @tester = testing_note.user
    @ticket = testing_note.ticket
    @project = testing_note.project
    
    mail({
      from:     @tester,
      to:       options.fetch(:to, @ticket.committers.map { |committer| OpenStruct.new(committer) }),
      cc:       options.fetch(:cc, @project.maintainers),
      subject:  "#{@tester.name} failed ticket ##{@ticket.number}",
      template: "failing_verdict"
    })
  end
  
  
  def maintainer_of_deploy(maintainer, deploy)
    @project = deploy.project
    @release = deploy.build_release
    @maintainer = maintainer
    
    @maintainer.reset_authentication_token!
    
    if @release.commits.empty? && @release.can_read_commits?
      @release.load_commits!
      @release.load_tickets!
      @release.build_changes_from_commits
    end
    
    mail({
      to:       @maintainer,
      subject:  "deploy complete!",
      template: "new_release"
    })
  end
  
  
  def configuration_error(project, message, options={})
    @project = project
    @message = message
    @additional_info = options[:additional_info]
    
    mail({
      to:       options.fetch(:to, @project.maintainers),
      subject:  "configuration error",
      template: "configuration_error"
    })
  end
  
  
protected
  
  
  def mail(options={})
    options[:subject] = "#{@project.name}: #{options[:subject]}"
    options[:template] = "project_notification/#{options[:template]}"
    super
  end
  
  
end

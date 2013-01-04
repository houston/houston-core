class ProjectMailer < ViewMailer
  
  
  def notice_of_failing_verdict(testing_note)
    @note = testing_note
    @tester = testing_note.user
    @ticket = testing_note.ticket
    @project = testing_note.project
    
    mail({
      from: format_email_address(@tester),
      to: @ticket.committers.map { |committer| "#{committer[:name]} <#{committer[:email]}>" },
      cc: @ticket.maintainers.map(&method(:format_email_address)),
      subject: "#{@project.name}: #{@tester.name} failed ticket ##{@ticket.number}",
      template: "project_notifications/failing_verdict"
    })
  end
  
  
  def notify_maintainer_of_deploy(maintainer, deploy)
    @project = deploy.project
    @release = deploy.build_release
    @maintainer = maintainer
    
    @maintainer.reset_authentication_token!
    
    if @release.commits.empty? && @release.can_read_commits?
      @release.load_commits!
      @release.load_tickets!
      @release.build_changes_from_commits
    end
    
    @project.maintainers.each(&:reset_authentication_token!)
    
    mail({
      to: format_email_address(@maintainer),
      subject: "#{@project.name}: new release",
      template: "project_notifications/new_release"
    })
  end
  
  
  def configuration_error(project, message, options={})
    @project = project
    @message = message
    @additional_info = options[:additional_info]
    
    to = options.fetch :to, @project.maintainers.map(&method(:format_email_address))
    
    mail({
      to: to,
      subject: "#{@project.name}: configuration error",
      template: "project_notifications/configuration_error"
    })
  end
  
  
end

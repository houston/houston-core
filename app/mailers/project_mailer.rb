class ProjectMailer < ViewMailer
  
  
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

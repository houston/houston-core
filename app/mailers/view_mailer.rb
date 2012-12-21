class ViewMailer < ActionMailer::Base
  default from: Houston.config.mailer_sender
  helper CommitHelper
  helper EmailHelper
  helper MarkdownHelper
  helper ReleaseHelper
  helper ScoreCardHelper
  helper StaticChartHelper
  helper TicketHelper
  helper UrlHelper
  
  
  def weekly_report(weekly_report, recipients)
    @date_range = weekly_report.date_range
    @projects = Project.scoped
    @title = weekly_report.title
    @date = weekly_report.date
    @for_email = true
    
    mail({
      to: recipients,
      subject: weekly_report.title,
      template: "weekly_report/show"
    })
  end
  
  
  def release(release, options={})
    @release = release
    @for_email = true
    
    to = options.fetch :to, release.notification_recipients.map(&method(:format_email_address))
    cc = options.fetch :cc, release.notification_recipients.map(&method(:format_email_address))
    
    mail({
      from: format_email_address(release.user),
      to: to,
      cc: cc,
      subject: "#{release.project.name} Update: changes have been deployed to #{release.environment.name}",
      template: "releases/show"
    })
  end
  
  
private
  
  
  def mail(options={})
    if block_given?
      super
    else
      template = options.delete(:template)
      mail(options) do |format|
        format.html do
          html = render_to_string(template: template, layout: "email")
          Premailer.new(html, with_html_string: true).to_inline_css
        end
      end
    end
  end
  
  
  def format_email_address(user)
    "#{user.name} <#{user.email}>"
  end
  
  
end

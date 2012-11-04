class WeeklyReportMailer < ActionMailer::Base
  default from: Houston.config.mailer_sender
  helper UrlHelper
  helper CommitHelper
  helper TicketHelper
  helper MarkdownHelper
  helper EmailHelper
  helper ScoreCardHelper
  helper StaticChartHelper
  
  
  def _new(weekly_report, recipients)
    mail({
      to: recipients,
      subject: weekly_report.title
    }) do |format|
      format.html do
        @date_range = weekly_report.date_range
        @projects = Project.scoped
        @title = weekly_report.title
        @date = weekly_report.date
        @for_email = true
        
        html = render_to_string(template: "weekly_report/show", layout: "email")
        Premailer.new(html, with_html_string: true).to_inline_css
      end
    end
    
  end
  
  
private
  
  
  def format_email_address(user)
    "#{user.name} <#{user.email}>"
  end
  
  
end

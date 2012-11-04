class ViewMailer < ActionMailer::Base
  default from: Houston.config.mailer_sender
  helper UrlHelper
  helper CommitHelper
  helper TicketHelper
  helper MarkdownHelper
  helper EmailHelper
  helper ScoreCardHelper
  helper StaticChartHelper
  
  
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
  
  
end

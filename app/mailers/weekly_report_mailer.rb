class WeeklyReportMailer < ActionMailer::Base
  default from: "EPDeveloper@cph.org"
  helper UrlHelper
  helper CommitHelper
  helper TicketHelper
  helper MarkdownHelper
  
  
  def _new(args={})
    mail({
      to: args[:recipients],
      subject: "Weekly Report"
    }) do |format|
      format.html { args[:body] }
    end
    
  end
  
  
private
  
  
  def format_email_address(user)
    "#{user.name} <#{user.email}>"
  end
  
  
end

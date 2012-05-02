class ChangelogMailer < ActionMailer::Base
  default from: "test@cph.org"
  helper UrlHelper
  
  def failed_verdict(note)
    @note = note
    @tester = note.user.name
    @ticket = note.ticket
    mail(to: 'epdeveloper@cph.org', subject: "#{@tester} has passed judgement (#notlookinggood)") do |format|
      format.html
    end
  end
  
end

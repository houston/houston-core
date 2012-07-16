class NotificationMailer < ActionMailer::Base
  default from: "EPDeveloper@cph.org"
  helper UrlHelper
  helper CommitHelper
  helper TicketHelper
  
  
  def on_post_receive(release)
    @release = release
    mail({
      to: release.maintainers.map(&method(:format_email_address)),
      subject: "@#{release.project.slug} new release"
    }) do |format|
      format.html
    end
  end
  
  
  def on_release(release)
    @release = release
    mail({
      to: release.notification_recipients.map(&method(:format_email_address)),
      cc: release.maintainers.map(&method(:format_email_address)),
      subject: release_announcement_for(release)
    }) do |format|
      format.html
    end
  end
  
  
  def on_fail_verdict(note)
    @note = note
    @tester = note.user
    @ticket = note.ticket
    mail({
      from: format_email_address(@tester),
      to: @ticket.committers.map { |committer| "#{committer[:name]} <#{committer[:email]}>" },
      cc: @ticket.maintainers.map(&method(:format_email_address)),
      subject: "@#{note.project.slug} [##{@ticket.number}] #{@tester.name} passed judgement #notlookinggood"
    }) do |format|
      format.html
    end
  end
  
  
private
  
  
  def format_email_address(user)
    "#{user.name} <#{user.email}>"
  end
  
  def release_announcement_for(release)
    case release.environment.slug # <-- knowledge of environments
    when "dev"; "Testing updates for #{release.project.name}"
    when "master"; "Release notice for #{release.project.name}"
    end
  end
  
  
end

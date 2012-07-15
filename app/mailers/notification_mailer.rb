class NotificationMailer < ActionMailer::Base
  DEVELOPERS = "EPDeveloper@cph.org"
  default from: DEVELOPERS
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
      to: recipients_for(release).map(&method(:format_email_address)),
      cc: DEVELOPERS,
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
  
  def recipients_for(release)
    roles = recipient_roles_for(release.environment)
    User.where(role: roles)
  end
  
  def recipient_roles_for(environment)
    case environment.slug # <-- knowledge of environments
    when "dev";     %w{Tester}
    when "master";  %w{Administrator Stakeholder Tester}
    end
  end
  
  def release_announcement_for(release)
    case release.environment.slug
    when "dev"; "Testing updates for #{release.project.name}"
    when "master"; "Release notice for #{release.project.name}"
    end
  end
  
  
end

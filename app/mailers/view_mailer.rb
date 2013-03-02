class ViewMailer < ActionMailer::Base
  include AbstractController::Callbacks
  
  def self.format_email_address(user)
    "#{user.name} <#{user.email}>"
  end
  
  default from: format_email_address(OpenStruct.new(name: Houston.config.title, email: Houston.config.mailer_sender))
  helper EmojiHelper
  helper BacktraceHelper
  helper CommitHelper
  helper EmailHelper
  helper MarkdownHelper
  helper ReleaseHelper
  helper ScoreCardHelper
  helper StaticChartHelper
  helper TicketHelper
  helper UrlHelper
  
  before_filter { @for_email = true }
  
  
  
  def weekly_report(weekly_report, recipients)
    @date_range = weekly_report.date_range
    @projects = Project.scoped
    @title = weekly_report.title
    @date = weekly_report.date
    
    mail({
      to: recipients,
      subject: weekly_report.title,
      template: "weekly_report/show"
    })
  end
  
  
protected
  
  
  def mail(options={})
    options[:from] = format_email_addresses(options[:from]) if options.key?(:from)
    options[:to] = format_email_addresses(options[:to]) if options.key?(:to)
    options[:cc] = format_email_addresses(options[:cc]) if options.key?(:cc)
    
    if block_given?
      super
    else
      template = options.delete(:template)
      super(options) do |format|
        format.html do
          html = render_to_string(template: template, layout: "email")
          Premailer.new(html, with_html_string: true).to_inline_css
        end
      end
    end
  end
  
  
  def format_email_addresses(recipients)
    Array.wrap(recipients).map &method(:format_email_address)
  end
  
  
  def format_email_address(recipient)
    if recipient.respond_to?(:name) && recipient.respond_to?(:email)
      self.class.format_email_address(recipient)
    else
      recipient
    end
  end
  
  
end

class ViewMailer < ActionMailer::Base
  include AbstractController::Callbacks
  
  
  # !todo: quote the display name
  def self.format_email_address(user)
    "#{user.name} <#{user.email}>"
  end
  
  default from: format_email_address(OpenStruct.new(name: Houston.config.title, email: Houston.config.mailer_sender))
  helper AvatarHelper
  helper BacktraceHelper
  helper CommitHelper
  helper DailyReportHelper
  helper EmailHelper
  helper EmojiHelper
  helper MarkdownHelper
  helper ReleaseHelper
  helper ScoreCardHelper
  helper StaticChartHelper
  helper TestRunHelper
  helper TicketHelper
  helper UrlHelper
  helper WeeklyReportHelper
  
  
  helper_method :can?, :cannot?, :current_ability
  delegate :can?, :cannot?, :to => :current_ability
  
  # c.f. https://github.com/ryanb/cancan/blob/1.6.7/lib/cancan/controller_additions.rb#L348-L350
  def current_ability
    @current_ability ||= ::Ability.new(User.new) # Treat email recipients as Guests, not Customers
  end
  
  
  before_filter { @for_email = true }
  
  
  def weekly_report(weekly_report, recipients)
    @projects = Project.unretired
    @title = weekly_report.title
    @weekly_report = weekly_report
    
    mail({
      to: recipients,
      subject: weekly_report.title,
      template: "weekly_report/show"
    })
  end
  
  
protected
  
  
  def mail(options={})
    options[:from] = format_email_addresses(options[:from]) if options.key?(:from)
    options[:to] = format_email_addresses(options[:to]).uniq if options.key?(:to)
    options[:cc] = format_email_addresses(options[:cc]).uniq if options.key?(:cc)
    
    # Don't CC anyone whose already being mailed
    options[:cc] -= options[:to] if options[:to] && options[:cc]
    
    return if Array(options[:to]).none? and Array(options[:cc]).none?
    
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

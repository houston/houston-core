class DailyReport
  
  def initialize(project, date=Date.today-1)
    @project = project
    @date = date.to_date
    @timespan = date.beginning_of_day...date.end_of_day
  end
  
  attr_reader :project, :date, :timespan
  
  
  
  def title
    "activity on #{date.strftime("%A, %B %e")}"
  end
  
  
  
  def recipients
    @recipients ||= project.followers.developers.unretired
  end
  
  def any_news?
    tickets_closed.any? || new_exceptions.any?
  end
  
  
  
  def tickets_closed
    @tickets_closed ||= project.tickets.closed_on(date).order(:resolution)
  end
  
  
  
  def exceptions
    @exceptions ||= project.error_tracker.problems_during(timespan)
  end
  
  def new_exceptions
    @new_exceptions ||= exceptions.select { |exception| timespan.cover? exception.first_notice_at }
  end
  
  
  
  def deliver!
    deliver_to!(recipients)
  end
  
  def deliver_to!(recipients)
    ProjectNotification.daily_report(self, recipients).deliver! if any_news?
  end
  
  def self.reports_with_news_and_recipients(date)
    reports_with_news_and_recipients = []
    Project.find_each do |project|
      report = DailyReport.new(project, date)
      reports_with_news_and_recipients << report if report.recipients.any? && report.any_news?
    end
    reports_with_news_and_recipients
  end
  
  def self.deliver_all!(date=Date.today-1)
    reports_with_news_and_recipients(date).map(&:deliver!)
  end
  
  
  
end

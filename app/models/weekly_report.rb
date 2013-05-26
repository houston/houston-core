class WeeklyReport
  
  def initialize(date=Date.today)
    date = date.to_date
    
    monday = date.beginning_of_week
    @date_range = monday..(6.days.since(monday))
    @year = monday.year
  end
  
  attr_reader :date_range, :year
  
  def title
    "Weekly Report for #{name_of_week}"
  end
  
  def name_of_week
    date_range.begin.strftime("%B %e")    
  end
  alias :to_s :name_of_week
  
  
  
  def sections
    { commits:      { commits: CommitStats.new(date_range) },
      exceptions:   { bugs: BugStats.new(date_range), notices: NoticeStats.new(date_range) },
      tickets:      {},
      maintenance:  {} }
  end
  
  
  
  def deliver_to!(recipients)
    ViewMailer.weekly_report(self, recipients).deliver!
  end
  
  class << self
    delegate :deliver_to!, :to => "self.new"
  end
  
end

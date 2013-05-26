class WeeklyReport
  
  def initialize(date=Date.today)
    date = date.to_date
    
    monday = date.beginning_of_week
    @date_range = monday..(6.days.since(monday))
  end
  
  attr_reader :date_range
  
  def title
    "Weekly Report for #{date_range.begin.strftime("%B %e")}"
  end
  
  
  
  def sections
    %w{commits exceptions tickets maintenance}
  end
  
  
  
  def deliver_to!(recipients)
    ViewMailer.weekly_report(self, recipients).deliver!
  end
  
  class << self
    delegate :deliver_to!, :to => "self.new"
  end
  
end

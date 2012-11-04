class WeeklyReport
  
  def initialize(date=Date.today)
    @date = date
    
    monday = @date.beginning_of_week
    @date_range = monday..(6.days.since(monday))
  end
  
  attr_reader :date, :date_range
  
  def title
    "Weekly Report for #{date.strftime("%B %e")}"
  end
  
  
  
  def deliver_to!(recipients)
    ViewMailer.weekly_report(self, recipients).deliver!
  end
  
  class << self
    delegate :deliver_to!, :to => "self.new"
  end
  
end

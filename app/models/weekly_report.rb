class WeeklyReport
  
  def initialize(date)
    @date = date
    
    monday = @date.beginning_of_week
    @date_range = monday..(6.days.since(monday))
  end
  
  attr_reader :date, :date_range
  
  def title
    "Weekly Report for #{date.strftime("%B %e")}"
  end
  
end

module WeeklyReportHelper
  
  def current_year?(year)
    year == Date.today.year
  end
  
  def next_week(weekly_report)
    1.week.since(weekly_report.date_range.begin)
  end
  
  def prev_week(weekly_report)
    1.week.until(weekly_report.date_range.begin)
  end
  
end

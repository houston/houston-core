module HistoricalWeeklyStats
  
  def history_range
    @history_range ||= ((weeks_of_history - 1).weeks.before(this_week.begin))..this_week.end
  end
  
  def history_weeks
    @history_weeks ||= history_range.step(7)
  end
  
  def new_history_vector
    Hash[history_weeks.zip([0] * weeks_of_history)]
  end
  
end

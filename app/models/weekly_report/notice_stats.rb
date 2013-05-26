class WeeklyReport
  class NoticeStats
    
    
    def initialize(date_range, projects: Project.scoped, weeks_of_history: 16)
      @weeks_of_history = weeks_of_history
      @date_range = date_range
      
      @weeks_of_errbit_history = 16
      date_range_multiweek2 = ((@weeks_of_errbit_history - 1).weeks.before(@date_range.begin))..@date_range.end
      errbit_history_weeks = date_range_multiweek2.step(7)
      
      @history_by_project = Hash[projects.zip]
      
      notices = Houston::Adapters::ErrorTracker::ErrbitAdapter.notices_during(date_range_multiweek2)
      
      notices.each do |notice|
        project = projects.detect { |project| project.extended_attributes["errbit_app_id"] == notice.app_id }
        next unless project
        
        notices_by_week = (@history_by_project[project] ||= Hash[errbit_history_weeks.zip([0]*@weeks_of_errbit_history)])
        
        week = notice.created_at.beginning_of_week.to_date
        next unless notices_by_week.key?(week) # we're getting notices for the monday after the sunday that should end the range
        notices_by_week[week] += 1
      end
    end
    
    
    
    attr_reader :history_by_project,
                :weeks_of_history
    
  end
end

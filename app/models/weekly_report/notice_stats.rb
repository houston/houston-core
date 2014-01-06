class WeeklyReport
  class NoticeStats
    include HistoricalWeeklyStats
    
    
    def initialize(this_week, projects: Project.scoped, weeks_of_history: 16)
      @this_week = this_week
      @weeks_of_history = weeks_of_history
      @history_by_project = {}
      
      notices = Houston::Adapters::ErrorTracker::ErrbitAdapter.notices_during(history_range)
      
      notices.each do |notice|
        project = projects.detect { |project| project.extended_attributes["errbit_app_id"] == notice.app_id.to_s }
        next unless project
        
        notices_by_week = @history_by_project[project] ||= new_history_vector
        
        week = notice.created_at.beginning_of_week.to_date
        next unless notices_by_week.key?(week) # we're getting notices for the monday after the sunday that should end the range
        notices_by_week[week] += 1
      end
    end
    
    
    attr_reader :this_week,
                :weeks_of_history,
                :history_by_project
    
  end
end

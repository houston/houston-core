class WeeklyReport
  class CommitStats
    include HistoricalWeeklyStats
    
    
    def initialize(this_week, weeks_of_history: 26, projects: Project.unretired)
      @this_week = this_week
      @weeks_of_history = weeks_of_history
      @count = 0 # commits this week
      @project_count = 0 # projects committed to this week
      
      weekday_by_wday = %w{Weekend Monday Tuesday Wednesday Thursday Friday Weekend}
      @weekdays = %w{Monday Tuesday Wednesday Thursday Friday Weekend}
      @by_weekday = Hash[@weekdays.zip([[], [], [], [], [], []])]
      @by_project = {}
      @history_by_project = Hash[projects.zip]
      
      time_range = @this_week.begin.beginning_of_day.to_time.to_i...@this_week.end.end_of_day.to_time.to_i
      time_range_multiweek = history_range.begin.beginning_of_day.to_time.to_i...history_range.end.end_of_day.to_time.to_i
      
      
      projects.each do |project|
        
        commits_by_week = @history_by_project[project] ||= new_history_vector
        commits_this_week = false
        
        commits = project.repo.all_commit_times
        
        commits.each do |commit|
          timestamp = commit.to_i
          
          if time_range_multiweek.include?(timestamp)
            time = Time.at(timestamp)
            date = time.to_date
            
            week = date.beginning_of_week
            next unless commits_by_week.key?(week)
            commits_by_week[week] = commits_by_week[week] + 1
            
            if time_range.include?(timestamp)
              weekday = weekday_by_wday[date.wday]
              weekday = "Weekend" unless (6..18).cover?(time.hour)
              
              @by_project[project] = @by_project.fetch(project, 0) + 1 unless weekday == "Weekend"
              @by_weekday[weekday].push(color: project.color, project: project.name)
              commits_this_week = true
              @count += 1
            end
          end
        end
        
        @project_count += 1 if commits_this_week
      end
    end
    
    
    
    attr_reader :this_week,
                :weeks_of_history,
                :weekdays,
                :count,
                :project_count,
                
                :by_weekday,
                :by_project,
                :history_by_project
    
    
    
  end
end

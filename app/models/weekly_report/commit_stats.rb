class WeeklyReport
  class CommitStats
    
    def initialize(date_range, weeks_of_history: 26)
      @weeks_of_history = weeks_of_history
      @date_range = date_range
      @count = 0
      @project_count = 0
      @projects = Project.scoped
      
      weekday_by_wday = %w{Weekend Monday Tuesday Wednesday Thursday Friday Weekend}
      @weekdays = %w{Monday Tuesday Wednesday Thursday Friday Weekend}
      @by_weekday = Hash[@weekdays.zip([[], [], [], [], [], []])]
      @weekday_commits_by_project = {}
      @commits_by_week_by_project = Hash[@projects.zip]
      
      date_range_multiweek = ((weeks_of_history - 1).weeks.before(@date_range.begin))..@date_range.end
      commit_history_weeks = date_range_multiweek.step(7)
      
      time_range = @date_range.begin.beginning_of_day.to_time.to_i...@date_range.end.end_of_day.to_time.to_i
      time_range_multiweek = date_range_multiweek.begin.beginning_of_day.to_time.to_i...date_range_multiweek.end.end_of_day.to_time.to_i
      
      
      
      
      @projects.each do |project|

        commits_by_week = (@commits_by_week_by_project[project] ||= Hash[commit_history_weeks.zip([0]*weeks_of_history)])
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

              @weekday_commits_by_project[project] = @weekday_commits_by_project.fetch(project, 0) + 1 unless weekday == "Weekend"
              @by_weekday[weekday].push(color: project.color, project: project.name)
              commits_this_week = true
              @count += 1
            end
          end
        end
        
        
        
        @project_count += 1 if commits_this_week
        end
    end
    
    
    
    attr_reader :weeks_of_history,
                :date_range,
                :weekdays,
                :count,
                :project_count,
                
                :by_weekday,
                :weekday_commits_by_project,
                :commits_by_week_by_project

    
    
    
  end
end

class WeeklyReport
  class BugStats
    
    
    def initialize(date_range, projects: Project.scoped, weeks_of_history: 16)
      @weeks_of_history = weeks_of_history
      @date_range = date_range
      # weekday_by_wday = %w{Weekend Monday Tuesday Wednesday Thursday Friday Weekend}
      # weekdays = %w{Monday Tuesday Wednesday Thursday Friday Weekend}
      total_bugs = 0
      
      # weeks_of_commit_history = 26
      # date_range_multiweek = ((weeks_of_commit_history - 1).weeks.before(@date_range.begin))..@date_range.end
      # 
      @weeks_of_errbit_history = 16
      date_range_multiweek2 = ((@weeks_of_errbit_history - 1).weeks.before(@date_range.begin))..@date_range.end
      errbit_history_weeks = date_range_multiweek2.step(7)
      # 
      # time_range = @date_range.begin.beginning_of_day.to_time.to_i...@date_range.end.end_of_day.to_time.to_i
      # time_range_multiweek = date_range_multiweek.begin.beginning_of_day.to_time.to_i...date_range_multiweek.end.end_of_day.to_time.to_i
      
      
      
      @by_project = {}
      @history_by_project = {} # Hash[projects.zip]
      @by_grade = {"A" => 0, "B" => 0, "C" => 0, "D" => 0, "F" => 0, " " => 0}
      bugs_by_possible_grade = {"A" => 0, "B" => 0, "C" => 0, "D" => 0, "F" => 0}
      @new_this_week = 0
      @fixed_this_week = 0
      @change_this_week = 0
      
      
      
      bugs = Houston::Adapters::ErrorTracker::ErrbitAdapter.problems_during(date_range_multiweek2)
      
      bugs.each do |bug|
        project = projects.detect { |project| project.extended_attributes["errbit_app_id"] == bug.app_id }
        next unless project
        
        bugs_by_week = (@history_by_project[project] ||= Hash[errbit_history_weeks.zip([0]*@weeks_of_errbit_history)])
        bug_counts = (@by_project[project] ||= {"fixed" => 0, "new" => 0, "open" => 0})
        
        errbit_history_weeks.each do |week|
          
          # open during week?
          if (bug.first_notice_at < week) && (bug.resolved_at.nil? || bug.resolved_at >= 7.days.after(week))
            bugs_by_week[week] += 1
          end
          
        end
        
        if (bug.first_notice_at < @date_range.end) && (bug.resolved_at.nil? || bug.resolved_at >= @date_range.begin)
          
          status = bug.resolved? ? "fixed" : (bug.first_notice_at >= @date_range.begin) ? "new" : "open"
          bug_counts[status] += 1
          
        end
        @new_this_week += 1 if bug.first_notice_at < @date_range.end && bug.first_notice_at > @date_range.begin
        @fixed_this_week += 1 if bug.resolved_at && bug.resolved_at < @date_range.end && bug.resolved_at > @date_range.begin
        
        
        time_unresolved = (bug.resolved_at || Time.now) - bug.first_notice_at
        grade = if    time_unresolved <  3.days then "A"
                elsif time_unresolved <  8.days then "B"
                elsif time_unresolved < 15.days then "C"
                elsif time_unresolved < 30.days then "D"
                else                                 "F"
                end
        
        if bug.resolved_at.nil?
          @by_grade[" "] += 1
        else
          @by_grade[grade] += 1
        end
        bugs_by_possible_grade[grade] += 1
        
      end
      
      @change_this_week = @new_this_week - @fixed_this_week
      
      
      
      points          = (@by_grade["A"] * 4.0 + 
                         @by_grade["B"] * 3.0 + 
                         @by_grade["C"] * 2.0 + 
                         @by_grade["D"] * 1.0)
      possible_points = (bugs_by_possible_grade["A"] * 4.0 + 
                         bugs_by_possible_grade["B"] * 3.0 + 
                         bugs_by_possible_grade["C"] * 2.0 + 
                         bugs_by_possible_grade["D"] * 1.0)
      @gpa_actual = (points / @by_grade.values.sum).round(2)
      @gpa_possible = (possible_points / bugs_by_possible_grade.values.sum).round(2)
      
    end
    
    
    
    attr_reader :by_grade,
                :gpa_actual,
                :gpa_possible,
                
                :new_this_week,
                :fixed_this_week,
                :change_this_week,
                
                :history_by_project,
                
                :by_project,
                :weeks_of_history
    
  end
end

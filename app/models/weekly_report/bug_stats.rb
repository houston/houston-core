class WeeklyReport
  class BugStats
    include HistoricalWeeklyStats
    
    
    def initialize(this_week, projects: Project.scoped, weeks_of_history: 16)
      @this_week = this_week
      @weeks_of_history = weeks_of_history
      
      total_bugs = 0
      @by_project = {}
      @history_by_project = {}
      @by_grade = {"A" => 0, "B" => 0, "C" => 0, "D" => 0, "F" => 0, " " => 0}
      bugs_by_possible_grade = {"A" => 0, "B" => 0, "C" => 0, "D" => 0, "F" => 0}
      @new_this_week = 0
      @fixed_this_week = 0
      @change_this_week = 0
      
      
      bugs = Houston::Adapters::ErrorTracker::ErrbitAdapter.problems_during(history_range)
      
      bugs.each do |bug|
        project = projects.detect { |project| project.extended_attributes["errbit_app_id"] == bug.app_id.to_s }
        next unless project
        
        bugs_by_week = @history_by_project[project] ||= new_history_vector
        bug_counts = (@by_project[project] ||= {"fixed" => 0, "new" => 0, "open" => 0})
        
        history_weeks.each do |week|
          
          # open during week?
          if (bug.first_notice_at < week) && (bug.resolved_at.nil? || bug.resolved_at >= 7.days.after(week))
            bugs_by_week[week] += 1
          end
          
        end
        
        if (bug.first_notice_at < @this_week.end) && (bug.resolved_at.nil? || bug.resolved_at >= @this_week.begin)
          
          status = bug.resolved? ? "fixed" : (bug.first_notice_at >= @this_week.begin) ? "new" : "open"
          bug_counts[status] += 1
          
        end
        @new_this_week += 1 if bug.first_notice_at < @this_week.end && bug.first_notice_at > @this_week.begin
        @fixed_this_week += 1 if bug.resolved_at && bug.resolved_at < @this_week.end && bug.resolved_at > @this_week.begin
        
        
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
    
    
    
    attr_reader :this_week,
                :weeks_of_history,
                
                :by_grade,
                :gpa_actual,
                :gpa_possible,
                
                :new_this_week,
                :fixed_this_week,
                :change_this_week,
                
                :history_by_project,
                
                :by_project
                
    
  end
end

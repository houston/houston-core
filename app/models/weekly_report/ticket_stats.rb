class WeeklyReport
  class TicketStats
    include HistoricalWeeklyStats
    
    
    def initialize(this_week, projects: Project.with_ticket_tracker, weeks_of_history: 16)
      @this_week = this_week
      @weeks_of_history = weeks_of_history
      @projects = projects
      
      color_by_type = Houston::TMI::TICKET_TYPE_COLORS
      
      @arrivals_by_week_by_project = {}
      @departures_by_week_by_project = {}
      @open_tickets_by_project = {}
      @by_severity_by_project = {}
      
      projects.each do |project|
        
        tickets_for_project = project.tickets
        
        arrivals = tickets_for_project.map { |ticket| ticket.created_at.to_date }.select { |created_at| history_range.cover?(created_at) }
        departures = tickets_for_project.map { |ticket| ticket.closed_at.try(:to_date) }.select { |closed_at| closed_at && history_range.cover?(closed_at) }
        
        arrivals_by_week = new_history_vector
        arrivals.each do |arrived_at|
          week = arrived_at.beginning_of_week
          arrivals_by_week[week] += 1 if arrivals_by_week.key?(week)
        end
        
        departures_by_week = new_history_vector
        departures.each do |departed_at|
          week = departed_at.beginning_of_week
          departures_by_week[week] += 1 if departures_by_week.key?(week)
        end
        
        @arrivals_by_week_by_project[project] = arrivals_by_week.values
        @departures_by_week_by_project[project] = departures_by_week.values
        
        # "Arrive" all the tickets created before the first week and still open
        @arrivals_by_week_by_project[project][0] += tickets_for_project.select { |ticket| ticket.created_at < history_range.first && ticket.closed_at.nil? }.count
        
        open_tickets_this_week = tickets_for_project.select { |ticket| ticket.created_at <= history_range.end && (ticket.closed_at.nil? || ticket.closed_at > history_range.end) }
        
        tickets_by_severity = @by_severity_by_project[project] = Hash[color_by_type.values.zip([0] * color_by_type.values.length)]
        open_tickets_this_week.each do |ticket|
          severity = ticket.type
          severity = nil if severity.blank?
          color = color_by_type[severity] # <-- Severity could be whatever the user has defined in Unfuddle: not necessarily what we've listed in config.rb
          tickets_by_severity[color] += 1 if tickets_by_severity.key?(color)
        end
        
        @open_tickets_by_project[project] = open_tickets_this_week.count
        
      end
    end
    
    
    attr_reader :this_week,
                :weeks_of_history,
                
                :projects,
                :by_severity_by_project,
                :arrivals_by_week_by_project,
                :departures_by_week_by_project,
                :open_tickets_by_project
    
  end
end

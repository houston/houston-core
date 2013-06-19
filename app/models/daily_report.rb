class DailyReport
  
  def initialize(project, date=Date.today-1)
    @project = project
    @date = date.to_date
    @timespan = date.beginning_of_day...date.end_of_day
  end
  
  attr_reader :project, :date, :timespan
  
  
  
  def title
    "activity on #{date.strftime("%A, %B %e")}"
  end
  
  
  
  def recipients
    @recipients ||= project.followers.developers
  end
  
  def any_news?
    queue_changes.any? || wip.any? || new_exceptions.any?
  end
  
  
  
  def wip
    return @wip if defined?(@wip)
    @wip = []
    @wip << [exceptions.count, :exceptions] if exceptions.count > 0
    @wip
  end
  
  
  
  def queue_changes
    @queue_changes ||= find_queue_changes!
  end
  
  def tickets_created
    @tickets_created ||= queue_changes.select { |change| change[:queue_before] == "Created" }
  end
  
  def tickets_closed
    @tickets_closed ||= queue_changes.select { |change| change[:queue_after] == "Closed" }
  end
  
  def tickets_with_queue_changes
    @tickets_with_queue_changes ||= queue_changes.select { |change| change[:queue_before] != "Created" && change[:queue_after] != "Closed" }
  end
  
  
  
  def exceptions
    @exceptions ||= project.error_tracker.problems_during(timespan)
  end
  
  def new_exceptions
    @new_exceptions ||= exceptions.select { |exception| timespan.cover? exception.first_notice_at }
  end
  
  
  
  def deliver!
    deliver_to!(recipients)
  end
  
  def deliver_to!(recipients)
    ProjectNotification.daily_report(self, recipients).deliver! if any_news?
  end
  
  def self.reports_with_news_and_recipients(date)
    reports_with_news_and_recipients = []
    Project.find_each do |project|
      report = DailyReport.new(project, date)
      reports_with_news_and_recipients << report if report.recipients.any? && report.any_news?
    end
    reports_with_news_and_recipients
  end
  
  def self.deliver_all!(date=Date.today-1)
    reports_with_news_and_recipients(date).map(&:deliver!)
  end
  
  
  
private
  
  
  
  def find_queue_changes!
    ticket_id_and_queue_before_timespan = select_ticket_id_and_latest_queue_before(timespan)
    ticket_id_and_queue_after_timespan = select_ticket_id_and_earliest_queue_after(timespan)
    queue_names = Hash[KanbanQueue.all.map { |queue| [queue.slug, queue.name] }]
    
    queue_changes = []
    
    ticket_id_and_queue_before_timespan.each do |hash|
      ticket_id = hash["ticket_id"].to_i
      queue = queue_names.fetch(hash["queue"], "Created")
      
      queue_changes.push(ticket_id: ticket_id, queue_before: queue, queue_after: "Closed")
    end
    
    ticket_id_and_queue_after_timespan.each do |hash|
      ticket_id = hash["ticket_id"].to_i
      queue = queue_names.fetch(hash["queue"], "Closed")
      
      queue_change = queue_changes.detect { |queue_change| queue_change[:ticket_id] == ticket_id }
      if queue_change
        queue_change[:queue_after] = queue
        queue_changes.delete(queue_change) if queue_change[:queue_before] == queue_change[:queue_after]
      else
        queue_changes.push(ticket_id: ticket_id, queue_before: "Created", queue_after: queue)
      end
    end
    
    remap_ticket_id_to_ticket(sort_by_queue_order(queue_changes))
  end
  
  
  
  def select_ticket_id_and_latest_queue_before(time)
    time = time.begin if time.is_a?(Range)
    select_ticket_id_and_queue ticket_queues.at(time).order("ticket_id, ticket_queues.created_at DESC")
  end
  
  def select_ticket_id_and_earliest_queue_after(time)
    time = time.end if time.is_a?(Range)
    select_ticket_id_and_queue ticket_queues.at(time).order("ticket_id, ticket_queues.created_at ASC")
  end
  
  def ticket_queues
    TicketQueue.for_project(project).for_kanban
  end
  
  def select_ticket_id_and_queue(scope)
    TicketQueue.connection.select_all(scope.select("DISTINCT ON (ticket_id) queue, ticket_id").to_sql)
  end
  
  
  
  def sort_by_queue_order(queue_changes)
    queue_positions = Hash[KanbanQueue.all.each_with_index.map { |queue, i| [queue.name, i] }]
    queue_positions["Created"] = -1
    queue_positions["Closed"] = 9999
    queue_changes.sort_by { |change| [
      queue_positions[change[:queue_before]],
      queue_positions[change[:queue_after]] ] }
  end
  
  def remap_ticket_id_to_ticket(queue_changes)
    ticket_ids = queue_changes.map { |queue_change| queue_change[:ticket_id] }
    tickets = project.tickets.where(id: ticket_ids)
    queue_changes.each do |queue_change|
      ticket_id = queue_change.delete(:ticket_id)
      ticket = tickets.detect { |ticket| ticket.id == ticket_id }
      queue_change[:ticket] = ticket
    end
  end
  
  
  
end

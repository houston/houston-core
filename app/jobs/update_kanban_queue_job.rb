class UpdateKanbanQueueJob
  
  class QuitAll < RuntimeError; end
  class QuitProject < RuntimeError; end
  
  
  def self.run!
    new.run!
  end
  
  def run!
    Project.where(ticket_tracker_name: "Unfuddle").each do |project|
      update_tickets_for_project!(project)
    end
  rescue QuitAll
  end
  
  def update_tickets_for_project!(project)
    KanbanQueue.all.each do |queue|
      update_tickets_for_project_and_queue!(project, queue)
    end
  rescue QuitProject
  end
  
  def update_tickets_for_project_and_queue!(project, queue)
    project.tickets.in_queue(queue, :refresh)
    
  rescue Houston::Adapters::TicketTracker::ConnectionError
    retry if (!connection_retry_count += 1) < 3
    connection_error!(project)
  rescue Houston::Adapters::TicketTracker::InvalidQueryError
    query_error!(project)
  ensure
    sleep 2 # give Unfuddle a break
  end
  
  
private
  
  
  def initialize
    @connection_retry_count = 0
  end
  
  attr_reader :connection_retry_count
  
  
  def connection_error!(project)
    Error.create(
      category: project.ticket_tracker_adapter.downcase,
      message: $!.message,
      backtrace: $!.backtrace)
    raise QuitAll
  end
    
  def query_error!(project)
    Error.create(
      project: project,
      category: "configuration",
      message: $!.message,
      backtrace: $!.backtrace)
    raise QuitProject
  end
  
  
end

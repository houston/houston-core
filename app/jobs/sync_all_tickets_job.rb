class SyncAllTicketsJob
  
  class QuitAll < RuntimeError; end
  
  
  def self.run!
    new.run!
  end
  
  def run!
    Project \
      .unretired
      .where(Project.arel_table[:ticket_tracker_name].not_in(%w{None Houston}))
      .each(&method(:update_tickets_for_project!))
  rescue QuitAll
  end
  
  def update_tickets_for_project!(project)
    SyncProjectTicketsJob.new(project).run!
    
  rescue Houston::Adapters::TicketTracker::ConnectionError
    retry if (connection_retry_count += 1) < 3
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
    Houston.report_exception $!
    raise QuitAll
  end
    
  def query_error!(project)
    Houston.report_exception $!
  end
  
end

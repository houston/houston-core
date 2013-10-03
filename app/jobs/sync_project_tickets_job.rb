class SyncProjectTicketsJob
  
  def initialize(project)
    @project = project
  end
  
  attr_reader :project
  
  def run!
    Rails.logger.debug "\e[33;1mStart sync job\e[0m"
    
    start_time = Time.now
    @project.update_column :ticket_tracker_sync_started_at, start_time
    
    tickets = project.all_tickets
    project.tickets.without(tickets).update_all(destroyed_at: Time.now)
    
    milestones = project.all_milestones
    project.milestones.without(milestones).update_all(destroyed_at: Time.now)
    
    @project.update_column :last_ticket_tracker_sync_at, Time.now
  ensure
    @project.update_column :ticket_tracker_sync_started_at, nil
    
    Rails.logger.debug "\e[33;1mFinish sync job in \e[4m%.2f\e[0;33;1m seconds\e[0m" % (Time.now - start_time)
  end
  
end

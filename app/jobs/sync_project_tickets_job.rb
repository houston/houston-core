class SyncProjectTicketsJob
  
  def initialize(project)
    @project = project
  end
  
  attr_reader :project
  
  def run!
    @project.update_column :ticket_tracker_sync_started_at, Time.now
    tickets = project.all_tickets
    project.tickets.not_numbered(tickets.map(&:number)).update_all(destroyed_at: Time.now)
    @project.update_column :last_ticket_tracker_sync_at, Time.now
  ensure
    @project.update_column :ticket_tracker_sync_started_at, nil
  end
  
end

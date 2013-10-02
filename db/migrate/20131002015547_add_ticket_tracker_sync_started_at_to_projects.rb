class AddTicketTrackerSyncStartedAtToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :ticket_tracker_sync_started_at, :timestamp
  end
end

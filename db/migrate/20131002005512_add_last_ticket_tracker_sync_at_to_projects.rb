class AddLastTicketTrackerSyncAtToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :last_ticket_tracker_sync_at, :timestamp
  end
end

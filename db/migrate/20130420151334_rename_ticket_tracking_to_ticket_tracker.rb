class RenameTicketTrackingToTicketTracker < ActiveRecord::Migration
  def change
    rename_column :projects, :ticket_tracking_adapter, :ticket_tracker_name
    rename_column :projects, :ticket_tracking_id, :ticket_tracker_id
  end
end

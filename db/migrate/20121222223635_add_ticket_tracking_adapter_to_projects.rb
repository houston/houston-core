class AddTicketTrackingAdapterToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :ticket_tracking_adapter, :string, :null => false, :default => "None"
    rename_column :projects, :unfuddle_id, :ticket_tracking_id

    Project.reset_column_information
    Project.all.each do |project|
      next if project.ticket_tracking_id.blank?
      project.update_column(:ticket_tracking_adapter, "Unfuddle")
    end
  end

  def down
    remove_column :projects, :ticket_tracking_adapter
    rename_column :projects, :ticket_tracking_id, :unfuddle_id
  end
end

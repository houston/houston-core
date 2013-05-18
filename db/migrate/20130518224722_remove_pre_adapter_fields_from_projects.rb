class RemovePreAdapterFieldsFromProjects < ActiveRecord::Migration
  def up
    remove_column :projects, :ticket_tracker_id
    remove_column :projects, :error_tracker_id
    remove_column :projects, :version_control_location
  end

  def down
    raise IrreversibleMigration
  end
end

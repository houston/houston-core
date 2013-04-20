class AddErrorTrackerNameToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :error_tracker_name, :string, :default => "None"
    
    Project.where("error_tracker_id != ''").update_all("error_tracker_name = 'Errbit'")
  end
  
  def down
    remove_column :projects, :error_tracker_name
  end
end

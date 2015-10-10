class AddVersionControlAdapterToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :version_control_adapter, :string, :null => false, :default => "None"
    rename_column :projects, :git_url, :version_control_location

    Project.reset_column_information
    Project.all.each do |project|
      next if project.version_control_location.blank?
      project.update_column(:version_control_adapter, "Git")
    end
  end

  def down
    remove_column :projects, :version_control_adapter
    rename_column :projects, :version_control_location, :git_url
  end
end

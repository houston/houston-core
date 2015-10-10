class AddExtendedAttributesToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :extended_attributes, :hstore

    Project.reset_column_information

    Project.find_each do |project|
      project.extended_attributes = {
        "unfuddle_project_id" => project.ticket_tracker_id,
        "git_location" => project.version_control_location,
        "errbit_app_id" => project.error_tracker_id }
      project.save!(validate: false)
    end
  end

  def down
    remove_column :projects, :extended_attributes
  end
end

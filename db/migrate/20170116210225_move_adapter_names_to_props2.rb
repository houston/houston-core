require "progressbar"

class MoveAdapterNamesToProps2 < ActiveRecord::Migration[5.0]
  def up
    projects = Project.unscoped
    pbar = ProgressBar.new("projects", projects.count)
    projects.find_each do |project|
      project.update_props!(
        "adapter.ciServer" => project.read_attribute(:ci_server_name),
        "adapter.ticketTracker" => project.read_attribute(:ticket_tracker_name),
        "adapter.errorTracker" => project.read_attribute(:error_tracker_name),
        "adapter.versionControl" => project.read_attribute(:version_control_name))
      pbar.inc
    end
    pbar.finish
  end
end

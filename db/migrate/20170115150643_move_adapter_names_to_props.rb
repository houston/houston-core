require "progressbar"

class MoveAdapterNamesToProps < ActiveRecord::Migration[5.0]
  def up
    projects = Project.unscoped
    pbar = ProgressBar.new("projects", projects.count)
    projects.find_each do |project|
      project.update_props!(
        "adapter.ciServer" => project.ci_server_name,
        "adapter.ticketTracker" => project.ticket_tracker_name,
        "adapter.errorTracker" => project.error_tracker_name,
        "adapter.versionControl" => project.version_control_name)
      pbar.inc
    end
    pbar.finish
  end
end

class CreateTasksForExistingTickets < ActiveRecord::Migration
  def up
    pbar = ProgressBar.new("Creating Tasks", Ticket.count)
    Ticket.find_each do |ticket|
      unless ticket.tasks.exists?
        first_release_at = ticket.releases.earliest.try :created_at
        first_commit_at = ticket.commits.earliest.try :created_at
        effort = ticket.extended_attributes["estimated_effort"]
        effort = effort.blank? ? nil : effort.to_d

        task = ticket.tasks.create!({
          description: ticket.summary,
          first_release_at: first_release_at,
          first_commit_at: first_commit_at,
          sprint_id: ticket.sprint_id,
          checked_out_at: ticket.checked_out_at,
          checked_out_by_id: ticket.checked_out_by_id,
          effort: effort
        })
        task.commits = ticket.commits
      end
      pbar.inc
    end
    pbar.finish
  end

  def down
    Task.delete_all
    execute "DELETE FROM commits_tasks"
    execute "DELETE FROM releases_tasks"
  end
end

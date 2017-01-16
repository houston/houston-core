class DropReleasesTicketsAndReleasesTasks < ActiveRecord::Migration[5.0]
  def up
    drop_table :releases_tickets
    drop_table :releases_tasks
  end
end

class LinkTasksAndReleases < ActiveRecord::Migration
  def change
    create_table :releases_tasks, :id => false do |t|
      t.references :release, :task
      t.index [:release_id, :task_id], :unique => true
    end
  end
end

class LinkTasksAndCommits < ActiveRecord::Migration
  def change
    create_table :commits_tasks, :id => false do |t|
      t.references :commit, :task
      t.index [:commit_id, :task_id], :unique => true
    end
  end
end

class AddCompletedAtToTasks < ActiveRecord::Migration
  def up
    add_column :tasks, :completed_at, :timestamp, null: true
    Task.reset_column_information

    Task.joins(:project)
      .where(Project.arel_table[:category].eq("Libraries"))
      .committed
      .update_all("completed_at=first_commit_at")

    Task.joins(:project)
      .where(Project.arel_table[:category].not_eq("Libraries"))
      .where.not(first_release_at: nil)
      .update_all("completed_at=first_release_at")
  end

  def down
    remove_column :tasks, :completed_at
  end
end

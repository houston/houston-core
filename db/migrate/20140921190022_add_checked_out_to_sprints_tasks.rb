class AddCheckedOutToSprintsTasks < ActiveRecord::Migration
  def up
    add_column :sprints_tasks, :checked_out_at, :timestamp
    add_column :sprints_tasks, :checked_out_by_id, :integer

    execute <<-SQL
      UPDATE sprints_tasks
        SET checked_out_at=tasks.checked_out_at,
            checked_out_by_id=tasks.checked_out_by_id
        FROM tasks
        WHERE sprints_tasks.task_id=tasks.id
    SQL
  end

  def down
    remove_column :sprints_tasks, :checked_out_at
    remove_column :sprints_tasks, :checked_out_by_id
  end
end

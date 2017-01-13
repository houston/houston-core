class DropSprintIdFromTasks < ActiveRecord::Migration[5.0]
  def up
    remove_column :tasks, :sprint_id
  end

  def down
    add_column :tasks, :sprint_id, :integer
  end
end

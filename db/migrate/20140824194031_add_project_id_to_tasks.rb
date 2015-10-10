class AddProjectIdToTasks < ActiveRecord::Migration
  def up
    add_column :tasks, :project_id, :integer
    execute "UPDATE tasks SET project_id=tickets.project_id FROM tickets WHERE ticket_id=tickets.id"
    change_column_null :tasks, :project_id, false
  end

  def down
    remove_column :tasks, :project_id
  end
end

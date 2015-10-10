class DropSprintsProjectId < ActiveRecord::Migration
  def up
    remove_column :sprints, :project_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

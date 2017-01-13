class AddProjectIdToCommits < ActiveRecord::Migration
  def up
    Commit.delete_all
    add_column :commits, :project_id, :integer, null: false
    add_index :commits, [:project_id]
  end

  def down
    remove_column :commits, :project_id
  end
end

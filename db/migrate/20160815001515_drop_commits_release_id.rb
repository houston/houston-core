class DropCommitsReleaseId < ActiveRecord::Migration
  def up
    remove_column :commits, :release_id
  end

  def down
    add_column :commits, :release_id, :integer
  end
end

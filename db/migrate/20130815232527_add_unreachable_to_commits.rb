class AddUnreachableToCommits < ActiveRecord::Migration
  def change
    add_column :commits, :unreachable, :boolean, null: false, default: false
    add_index :commits, :unreachable
  end
end

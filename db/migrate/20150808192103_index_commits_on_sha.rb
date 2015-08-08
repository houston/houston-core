class IndexCommitsOnSha < ActiveRecord::Migration
  def change
    add_index :commits, :sha, unique: true
  end
end

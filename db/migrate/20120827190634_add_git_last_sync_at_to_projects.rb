class AddGitLastSyncAtToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :git_last_sync_at, :timestamp
  end
end

class RenameTestRunsCommitToSha < ActiveRecord::Migration
  def up
    rename_column :test_runs, :commit, :sha
  end

  def down
    rename_column :test_runs, :sha, :commit
  end
end

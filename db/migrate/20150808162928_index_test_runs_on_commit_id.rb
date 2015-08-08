class IndexTestRunsOnCommitId < ActiveRecord::Migration
  def change
    add_index :test_runs, :commit_id, unique: true
  end
end

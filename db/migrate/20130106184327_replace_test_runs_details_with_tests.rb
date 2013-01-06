class ReplaceTestRunsDetailsWithTests < ActiveRecord::Migration
  def up
    remove_column :test_runs, :details
    add_column :test_runs, :tests, :text
  end

  def down
    remove_column :test_runs, :tests
    add_column :test_runs, :details, :hstore
  end
end

class AddCoverageToTestRuns < ActiveRecord::Migration
  def change
    add_column :test_runs, :coverage, :text
    add_column :test_runs, :covered_percent, :decimal, :precision => 6, :scale => 5
    add_column :test_runs, :covered_strength, :decimal, :precision => 6, :scale => 5
  end
end

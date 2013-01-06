class AddTotalCountToTestRuns < ActiveRecord::Migration
  def change
    add_column :test_runs, :total_count, :integer
  end
end

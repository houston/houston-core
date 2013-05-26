class AddRegressionCountToTestRuns < ActiveRecord::Migration
  def change
    add_column :test_runs, :regression_count, :integer
  end
end

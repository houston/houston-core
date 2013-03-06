class AddBranchToTestRuns < ActiveRecord::Migration
  def change
    add_column :test_runs, :branch, :string, :null => true
  end
end

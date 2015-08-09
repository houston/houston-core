class AddComparedToTestRuns < ActiveRecord::Migration
  def change
    add_column :test_runs, :compared, :boolean, null: false, default: false
  end
end

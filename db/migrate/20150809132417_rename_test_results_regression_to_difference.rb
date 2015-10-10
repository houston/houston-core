class RenameTestResultsRegressionToDifference < ActiveRecord::Migration
  def up
    rename_column :test_results, :regression, :different
    add_column :test_results, :new_test, :boolean, null: true, default: nil
  end

  def down
    remove_column :test_results, :new_test
    rename_column :test_results, :different, :regression
  end
end

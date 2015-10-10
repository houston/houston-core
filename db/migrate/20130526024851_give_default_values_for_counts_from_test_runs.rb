class GiveDefaultValuesForCountsFromTestRuns < ActiveRecord::Migration
  def up
    [:duration, :fail_count, :pass_count, :skip_count, :total_count, :regression_count].each do |column|
      change_column :test_runs, column, :integer, null: false, default: 0
    end

    change_column :test_runs, :covered_percent, :decimal, precision: 6, scale: 5, null: false, default: 0
    change_column :test_runs, :covered_strength, :decimal, precision: 6, scale: 5, null: false, default: 0
  end

  def down
    [:duration, :fail_count, :pass_count, :skip_count, :total_count, :regression_count].each do |column|
      change_column :test_runs, column, :integer
    end

    change_column :test_runs, :covered_percent, :decimal, precision: 6, scale: 5
    change_column :test_runs, :covered_strength, :decimal, precision: 6, scale: 5
  end
end

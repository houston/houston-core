class DropMilestonesStartDate < ActiveRecord::Migration[5.0]
  def up
    remove_column :milestones, :start_date
  end

  def down
    add_column :milestones, :start_date, :date
  end
end

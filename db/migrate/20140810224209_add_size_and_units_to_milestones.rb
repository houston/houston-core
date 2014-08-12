class AddSizeAndUnitsToMilestones < ActiveRecord::Migration
  def change
    add_column :milestones, :size, :integer
    add_column :milestones, :units, :string
    add_column :milestones, :start_date, :date
  end
end

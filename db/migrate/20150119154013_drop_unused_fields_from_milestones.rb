class DropUnusedFieldsFromMilestones < ActiveRecord::Migration
  def up
    remove_column :milestones, :size
    remove_column :milestones, :units
    remove_column :milestones, :position
  end

  def down
    add_column :milestones, :size, :integer
    add_column :milestones, :units, :string
    add_column :milestones, :position, :integer
  end
end

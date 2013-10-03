class AddDestroyedAtToMilestones < ActiveRecord::Migration
  def change
    add_column :milestones, :destroyed_at, :timestamp
    add_index :milestones, :destroyed_at
  end
end

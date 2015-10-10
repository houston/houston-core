class RemoveNewRelicIdFromProjects < ActiveRecord::Migration
  def up
    remove_column :projects, :new_relic_id
  end

  def down
    add_column :projects, :new_relic_id, :integer
  end
end

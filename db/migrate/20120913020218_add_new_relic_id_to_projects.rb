class AddNewRelicIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :new_relic_id, :integer
  end
end

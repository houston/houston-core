class AddDeploysCompletedAt < ActiveRecord::Migration
  def up
    add_column :deploys, :completed_at, :timestamp
    execute "UPDATE deploys SET completed_at=created_at"
  end

  def down
    remove_column :deploys, :completed_at
  end
end

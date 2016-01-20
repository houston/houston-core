class AddSuccessfulToDeploys < ActiveRecord::Migration
  def up
    add_column :deploys, :successful, :boolean, null: false, default: false
    execute "UPDATE deploys SET successful='t'"
  end

  def down
    remove_column :deploys, :successful
  end
end

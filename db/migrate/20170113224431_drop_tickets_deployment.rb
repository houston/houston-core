class DropTicketsDeployment < ActiveRecord::Migration[5.0]
  def up
    remove_column :tickets, :deployment
  end

  def down
    add_column :tickets, :deployment, :timestamp
  end
end

class DropTicketsReopenedAt < ActiveRecord::Migration[5.0]
  def up
    remove_column :tickets, :reopened_at
  end

  def down
    add_column :tickets, :reopened_at, :timestamp
  end
end

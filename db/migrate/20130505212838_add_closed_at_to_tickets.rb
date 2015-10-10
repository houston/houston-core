class AddClosedAtToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :closed_at, :timestamp
  end

  def down
    remove_column :tickets, :closed_at
  end
end

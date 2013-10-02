class AddDestroyedAtToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :destroyed_at, :timestamp
    add_index :tickets, :destroyed_at
  end
end

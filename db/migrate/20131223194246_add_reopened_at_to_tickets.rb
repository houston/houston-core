class AddReopenedAtToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :reopened_at, :timestamp
  end
end

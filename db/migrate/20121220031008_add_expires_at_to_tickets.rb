class AddExpiresAtToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :expires_at, :timestamp
  end
end

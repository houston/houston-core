class AddCheckedOutToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :checked_out_at, :timestamp
    add_column :tickets, :checked_out_by_id, :integer
  end
end

class AddGoldmineToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :goldmine, :string
  end
end

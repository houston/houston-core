class AddResolutionToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :resolution, :string, null: false, default: ""
    add_index :tickets, :resolution
  end
end

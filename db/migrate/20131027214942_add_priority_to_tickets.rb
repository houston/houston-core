class AddPriorityToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :priority, :string, null: false, default: "normal"
  end
end

class AddTypeToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :type, :string
  end

  def down
    remove_column :tickets, :type
  end
end

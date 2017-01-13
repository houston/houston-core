class DropPrerequisitesFromTickets < ActiveRecord::Migration[5.0]
  def up
    remove_column :tickets, :prerequisites
  end

  def down
    add_column :tickets, :prerequisites, :integer, array: true
  end
end

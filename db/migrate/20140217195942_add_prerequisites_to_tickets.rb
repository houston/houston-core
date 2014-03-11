class AddPrerequisitesToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :prerequisites, :integer, array: true
  end
end

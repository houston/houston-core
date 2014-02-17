class AddPrerequisitesToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :prerequisites, :integer_array
  end
end

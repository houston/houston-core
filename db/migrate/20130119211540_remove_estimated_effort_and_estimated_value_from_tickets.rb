class RemoveEstimatedEffortAndEstimatedValueFromTickets < ActiveRecord::Migration
  def up
    remove_column :tickets, :estimated_effort
    remove_column :tickets, :estimated_value
  end

  def down
    add_column :tickets, :estimated_effort, :decimal, precision: 9, scale: 2
    add_column :tickets, :estimated_value, :decimal, precision: 11, scale: 2
  end
end

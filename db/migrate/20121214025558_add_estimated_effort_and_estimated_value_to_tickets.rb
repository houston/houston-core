class AddEstimatedEffortAndEstimatedValueToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :estimated_effort, :decimal, precision: 9, scale: 2
    add_column :tickets, :estimated_value, :decimal, precision: 11, scale: 2
  end
end

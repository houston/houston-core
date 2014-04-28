class PreventTicketNumberFromBeingNull < ActiveRecord::Migration
  def change
    change_column_null :tickets, :number, false
  end
end

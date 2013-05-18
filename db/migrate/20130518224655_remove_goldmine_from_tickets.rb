class RemoveGoldmineFromTickets < ActiveRecord::Migration
  def up
    remove_column :tickets, :goldmine
  end

  def down
    raise IrreversibleMigration
  end
end

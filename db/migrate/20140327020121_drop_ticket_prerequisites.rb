class DropTicketPrerequisites < ActiveRecord::Migration
  def up
    drop_table :ticket_prerequisites
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

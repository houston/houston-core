class DropEnvironments < ActiveRecord::Migration
  def up
    drop_table :environments
  end

  def down
    raise IrreversibleMigration
  end
end

class DropTableChanges < ActiveRecord::Migration
  def up
    drop_table :changes
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

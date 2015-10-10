class DropTableErrors < ActiveRecord::Migration
  def up
    drop_table :errors
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

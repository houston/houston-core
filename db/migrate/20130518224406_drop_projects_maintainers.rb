class DropProjectsMaintainers < ActiveRecord::Migration
  def up
    drop_table :projects_maintainers
  end

  def down
    raise IrreversibleMigration
  end
end

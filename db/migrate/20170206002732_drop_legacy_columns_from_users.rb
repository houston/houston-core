class DropLegacyColumnsFromUsers < ActiveRecord::Migration[5.0]
  def up
    remove_column :users, :legacy_role
    remove_column :users, :legacy_administrator
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

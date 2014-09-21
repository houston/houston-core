class DropUsersName < ActiveRecord::Migration
  def up
    remove_column :users, :name
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

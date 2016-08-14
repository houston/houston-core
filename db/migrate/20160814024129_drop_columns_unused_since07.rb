class DropColumnsUnusedSince07 < ActiveRecord::Migration
  def up
    remove_column :users, :unfuddle_id
    remove_column :users, :view_options
    remove_column :projects, :extended_attributes
    remove_column :projects, :view_options
  end

  def down
    raise IrreversibleMigration
  end
end

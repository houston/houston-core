class DropUnusedTables < ActiveRecord::Migration
  def up
    remove_column :projects, :gemnasium_slug
    remove_column :users, :old_environments_subscribed_to
  end

  def down
    add_column :projects, :gemnasium_slug, :string
    add_column :users, :old_environments_subscribed_to, :string, default: "", null: false
  end
end

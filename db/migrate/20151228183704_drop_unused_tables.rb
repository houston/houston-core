class DropUnusedTables < ActiveRecord::Migration
  def up
    remove_column :deploys, :environment_id
    drop_table :historical_heads
    remove_column :projects, :gemnasium_slug
    remove_column :pull_requests, :labels
    remove_column :pull_requests, :old_labels
    remove_column :tasks, :checked_out_at
    remove_column :tasks, :checked_out_by_id
    remove_column :tickets, :checked_out_at
    remove_column :tickets, :checked_out_by_id
    remove_column :users, :old_environments_subscribed_to
  end

  def down
    add_column :deploys, :environment_id, :integer
    create_table :historical_heads do |t|
      t.integer :project_id, null: false
      t.hstore :branches, null: false, default: {}
      t.timestamps
    end
    add_column :projects, :gemnasium_slug, :string
    add_column :pull_requests, :old_labels, :text, default: "", null: false
    add_column :pull_requests, :labels, :text, array: true, default: [], null: false
    add_column :tasks, :checked_out_at, :timestamp
    add_column :tasks, :checked_out_by_id, :integer
    add_column :tickets, :checked_out_at, :timestampd
    add_column :tickets, :checked_out_by_id, :integer
    add_column :users, :old_environments_subscribed_to, :string, default: "", null: false
  end
end

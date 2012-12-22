class RemoveUnusedFieldsFromProjects < ActiveRecord::Migration
  def up
    remove_column :projects, :kanban_field
    remove_column :projects, :development_id
    remove_column :projects, :testing_id
    remove_column :projects, :production_id
    remove_column :projects, :assign_health_query
    remove_column :projects, :new_tickets_query
    remove_column :projects, :git_last_sync_at
  end

  def down
    add_column :projects, :kanban_field, :string
    add_column :projects, :development_id, :integer
    add_column :projects, :testing_id, :integer
    add_column :projects, :production_id, :integer
    add_column :projects, :assign_health_query, :string
    add_column :projects, :new_tickets_query, :string
    add_column :projects, :git_last_sync_at, :datetime
  end
end

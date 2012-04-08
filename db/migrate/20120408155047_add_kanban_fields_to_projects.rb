class AddKanbanFieldsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :color, :string
    add_column :projects, :kanban_field, :string
    add_column :projects, :development_id, :integer
    add_column :projects, :testing_id, :integer
    add_column :projects, :production_id, :integer
  end
end

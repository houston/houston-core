class AddHealthFieldsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :assign_health_query, :string
    add_column :projects, :new_tickets_query, :string
  end
end

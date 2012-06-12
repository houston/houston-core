class AddCachedQueriesToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :cached_queries, :text
  end
end

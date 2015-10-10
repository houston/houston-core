class RemoveCachedQueriesFromProjects < ActiveRecord::Migration
  def up
    remove_column :projects, :cached_queries
  end

  def down
    add_column :projects, :cached_queries, :text
  end
end

class RequireProjectsToHaveNameAndSlug < ActiveRecord::Migration
  def change
    change_column_null :projects, :name, false
    change_column_null :projects, :slug, false
  end
end

class RequireProjectSlugsToBeUnique < ActiveRecord::Migration
  def change
    add_index :projects, :slug, unique: true
  end
end

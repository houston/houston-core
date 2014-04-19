class AddGemnasiumSlugToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :gemnasium_slug, :string
  end
end

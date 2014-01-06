class AddOptionsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :view_options, :hstore
  end
end

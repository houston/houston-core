class AddRetiredAtToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :retired_at, :timestamp
  end
end

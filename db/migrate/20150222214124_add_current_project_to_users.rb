class AddCurrentProjectToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_project_id, :integer
  end
end

class AddErrbitAppIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :errbit_app_id, :string
  end
end

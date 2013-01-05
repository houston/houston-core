class AddCIAdapterToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :ci_adapter, :string, :null => false, :default => "None"
  end
end

class RenameProjectsVersionControlAdapterToVersionControlName < ActiveRecord::Migration
  def change
    rename_column :projects, :version_control_adapter, :version_control_name
  end
end

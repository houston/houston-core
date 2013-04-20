class RenameProjectsCiAdapterToCiServerName < ActiveRecord::Migration
  def change
    rename_column :projects, :ci_adapter, :ci_server_name
  end
end

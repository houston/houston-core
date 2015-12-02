class RequireProjectsToHaveColor < ActiveRecord::Migration
  def up
    execute "UPDATE projects SET color='default' WHERE color IS NULL"
    change_column_default :projects, :color, "default"
    change_column_null  :projects, :color, false
  end

  def down
    change_column_null  :projects, :color, true
    change_column_default :projects, :color, nil
    execute "UPDATE projects SET color=NULL WHERE color='default'"
  end
end

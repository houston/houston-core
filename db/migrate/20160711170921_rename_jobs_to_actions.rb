class RenameJobsToActions < ActiveRecord::Migration
  def change
    rename_table :jobs, :actions
  end
end

class RenameProjectsErrbitAppIdToErrorTrackerId < ActiveRecord::Migration
  def change
    rename_column :projects, :errbit_app_id, :error_tracker_id
  end
end

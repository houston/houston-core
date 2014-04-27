class PreventReleaseChangesFromBeingNull < ActiveRecord::Migration
  def change
    change_column_default :releases, :release_changes, ""
    change_column_null :releases, :release_changes, false
  end
end

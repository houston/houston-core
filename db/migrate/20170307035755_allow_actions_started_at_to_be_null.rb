class AllowActionsStartedAtToBeNull < ActiveRecord::Migration[5.0]
  def change
    change_column_null :actions, :started_at, true
  end
end

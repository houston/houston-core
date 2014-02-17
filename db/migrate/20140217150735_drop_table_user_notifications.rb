class DropTableUserNotifications < ActiveRecord::Migration
  def up
    drop_table :user_notifications
  end

  def down
    raise IrreversibleMigration
  end
end

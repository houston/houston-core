class CreateUserNotifications < ActiveRecord::Migration
  def up
    create_table :user_notifications do |t|
      t.references :user
      t.references :project
      t.string :environment

      t.timestamps
    end

    User.unscoped do
      User.find_each(&:save_default_notifications)
    end
  end

  def down
    drop_table :user_notifications
  end
end

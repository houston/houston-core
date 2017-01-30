class DropUsersEnvironmentsSubscribedTo < ActiveRecord::Migration[5.0]
  def up
    remove_column :users, :environments_subscribed_to
  end

  def down
    add_column :users, :environments_subscribed_to, :string, :null => false, :default => ""
  end
end

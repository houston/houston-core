class MakeUsersEnvironmentsSubscribedToAnArray < ActiveRecord::Migration
  def up
    rename_column :users, :environments_subscribed_to, :old_environments_subscribed_to
    add_column :users, :environments_subscribed_to, :text, array: true, default: [], null: false
    
    User.reset_column_information
    User.find_each do |user|
      environments = JSON.load user.old_environments_subscribed_to
      next if environments.nil? or environments.empty?
      user.update_column :environments_subscribed_to, environments
    end
  end
  
  def down
    remove_column :users, :environments_subscribed_to
    rename_column :users, :old_environments_subscribed_to, :environments_subscribed_to
  end
end

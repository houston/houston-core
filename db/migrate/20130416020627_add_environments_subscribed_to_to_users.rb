class AddEnvironmentsSubscribedToToUsers < ActiveRecord::Migration
  def up
    add_column :users, :environments_subscribed_to, :string, :null => false, :default => ""

    User.reset_column_information

    User.find_each do |user|
      user.environments_subscribed_to = User.connection.select_values("SELECT environment_name FROM user_notifications WHERE user_id=#{user.id} GROUP BY environment_name HAVING COUNT(id)>0") & Houston.config.environments
      puts "#{user.name} is subscribed to release notices for #{user.environments_subscribed_to.to_sentence}"
      user.save
    end
  end

  def down
    remove_column :users, :environments_subscribed_to
  end
end

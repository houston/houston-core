class AddEmailAddressesToUsers < ActiveRecord::Migration
  def up
    add_column :users, :email_addresses, :text, array: true
    add_index :users, :email_addresses

    User.reset_column_information

    User.unscoped.find_each do |user|
      user.email_addresses = [user.email]
      user.save!
    end
  end

  def down
    remove_index :users, :email_addresses
    remove_column :users, :email_addresses
  end
end

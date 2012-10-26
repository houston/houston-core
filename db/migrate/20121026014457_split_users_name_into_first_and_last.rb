class SplitUsersNameIntoFirstAndLast < ActiveRecord::Migration
  def up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    
    User.reset_column_information
    User.transaction do 
      User.all.each do |user|
        names = user.read_attribute(:name).split(" ")
        names = names * 2 if names.length == 1
        user.first_name, user.last_name = *names
        puts "\"#{user.name}\" => \"#{user.first_name}\", \"#{user.last_name}\""
        user.save!
      end
    end
  end

  def down
    remove_column :users, :first_name
    remove_column :users, :last_name
  end
end

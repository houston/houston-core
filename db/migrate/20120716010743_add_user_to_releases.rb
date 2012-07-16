class AddUserToReleases < ActiveRecord::Migration
  def up
    add_column :releases, :user_id, :integer
    
    admin = User.administrators.first
    Release.update_all(user_id: admin.id)
    
    change_column_null :releases, :user_id, false
  end
  
  def down
    remove_column :releases, :user_id
  end
end

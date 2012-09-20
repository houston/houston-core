class AddAdministratorToUsers < ActiveRecord::Migration
  def up
    add_column :users, :administrator, :boolean, :default => false
    
    User.where(role: "Administrator").update_all(administrator: true, role: "Developer")
  end
  
  def down
    User.where(administrator: true).update_all(role: "Administrator")
    
    remove_column :users, :administrator
  end
end

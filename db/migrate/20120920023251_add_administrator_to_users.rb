class AddAdministratorToUsers < ActiveRecord::Migration
  def up
    add_column :users, :administrator, :boolean, :default => false

    User.unscoped do
      User.where(role: "Administrator").update_all(administrator: true, role: "Developer")
    end
  end

  def down
    User.unscoped do
      User.where(administrator: true).update_all(role: "Administrator")
    end

    remove_column :users, :administrator
  end
end

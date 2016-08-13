class RepurposeUsersRole < ActiveRecord::Migration
  def up
    rename_column :users, :role, :legacy_role
    rename_column :users, :administrator, :legacy_administrator

    add_column :users, :role, :string, default: "Member"
    User.where(legacy_administrator: true).update_all(role: "Owner")
  end

  def down
    remove_column :users, :role

    rename_column :users, :legacy_role, :role
    rename_column :users, :legacy_administrator, :administrator
  end
end

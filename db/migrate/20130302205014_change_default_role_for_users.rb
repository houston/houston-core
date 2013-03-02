class ChangeDefaultRoleForUsers < ActiveRecord::Migration
  def up
    change_column_default :users, :role, "Guest"
  end

  def down
  end
end

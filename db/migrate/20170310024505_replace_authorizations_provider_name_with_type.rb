class ReplaceAuthorizationsProviderNameWithType < ActiveRecord::Migration[5.0]
  def up
    Authorization.delete_all
    remove_column :authorizations, :provider_name
    add_column :authorizations, :type, :string, null: false
  end

  def down
    remove_column :authorizations, :type
    add_column :authorizations, :provider_name, :string, null: false
  end
end

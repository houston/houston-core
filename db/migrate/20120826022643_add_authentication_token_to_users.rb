class AddAuthenticationTokenToUsers < ActiveRecord::Migration
  def up
    add_column :users, :authentication_token, :string
    add_index :users, :authentication_token

    User.unscoped { User.find_each(&:ensure_authentication_token) }
  end

  def down
    remove_index :users, :authentication_token
    remove_column :users, :authentication_token
  end
end

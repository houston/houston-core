class AddNicknameToUsers < ActiveRecord::Migration
  def up
    add_column :users, :nickname, :string
  end
end

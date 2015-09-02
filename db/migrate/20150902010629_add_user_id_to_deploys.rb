class AddUserIdToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :user_id, :integer
  end
end

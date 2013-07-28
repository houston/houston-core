class AddRetiredAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :retired_at, :timestamp
  end
end

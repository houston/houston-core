class AddUnfuddleIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :unfuddle_id, :integer
  end
end

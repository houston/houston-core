class AddUserToPersistentTriggers < ActiveRecord::Migration[5.0]
  def change
    add_column :persistent_triggers, :user_id, :integer, null: false
  end
end

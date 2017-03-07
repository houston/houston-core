class AddCreatedAtToActions < ActiveRecord::Migration[5.0]
  def up
    add_column :actions, :created_at, :timestamp
    Action.update_all "created_at=started_at"
    change_column_null :actions, :created_at, false
  end

  def down
    remove_column :actions, :created_at
  end
end

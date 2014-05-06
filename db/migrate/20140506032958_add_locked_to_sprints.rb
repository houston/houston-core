class AddLockedToSprints < ActiveRecord::Migration
  def change
    add_column :sprints, :locked, :boolean, null: false, default: false
  end
end

class DropSettings < ActiveRecord::Migration[5.0]
  def up
    drop_table :settings
  end

  def down
    create_table :settings do |t|
      t.string :name, null: false
      t.string :value, null: false
    end
  end
end

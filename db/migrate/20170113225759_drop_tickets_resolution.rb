class DropTicketsResolution < ActiveRecord::Migration[5.0]
  def up
    remove_index :tickets, :resolution
    remove_column :tickets, :resolution
  end

  def down
    add_column :tickets, :resolution, :string, null: false, default: ""
    add_index :tickets, :resolution
  end
end

class DropNameFromAuthorizations < ActiveRecord::Migration[5.0]
  def up
    remove_column :authorizations, :name
  end

  def down
    add_column :authorizations, :name, :string
  end
end

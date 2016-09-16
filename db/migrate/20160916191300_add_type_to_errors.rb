class AddTypeToErrors < ActiveRecord::Migration[5.0]
  def change
    add_column :errors, :type, :string
  end
end

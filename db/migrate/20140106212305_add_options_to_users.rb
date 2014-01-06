class AddOptionsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :view_options, :hstore
  end
end

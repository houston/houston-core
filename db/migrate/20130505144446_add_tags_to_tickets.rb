class AddTagsToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :tags, :string, array: true
  end

  def down
    remove_column :tickets, :tags
  end
end

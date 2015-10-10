class AddUnfuddleIdToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :unfuddle_id, :integer
  end

  def down
    remove_column :tickets, :unfuddle_id
  end
end

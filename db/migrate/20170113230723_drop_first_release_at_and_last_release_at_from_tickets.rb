class DropFirstReleaseAtAndLastReleaseAtFromTickets < ActiveRecord::Migration[5.0]
  def up
    remove_column :tickets, :first_release_at
    remove_column :tickets, :last_release_at
  end

  def down
    add_column :tickets, :first_release_at, :timestamp
    add_column :tickets, :last_release_at, :timestamp
  end
end

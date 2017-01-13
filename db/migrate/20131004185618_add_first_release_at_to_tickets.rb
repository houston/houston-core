class AddFirstReleaseAtToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :first_release_at, :timestamp
  end

  def down
    remove_column :tickets, :first_release_at
  end
end

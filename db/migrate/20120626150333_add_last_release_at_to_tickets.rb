class AddLastReleaseAtToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :last_release_at, :timestamp
  end

  def down
    remove_column :tickets, :last_release_at
  end
end

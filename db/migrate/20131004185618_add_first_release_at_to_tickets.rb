class AddFirstReleaseAtToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :first_release_at, :timestamp

    Ticket.all.each do |ticket|
      first_release = ticket.releases.last
      ticket.update_column(:first_release_at, first_release.created_at) if first_release
    end
  end

  def down
    remove_column :tickets, :first_release_at
  end
end

class AddLastReleaseAtToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :last_release_at, :timestamp

    Ticket.unscoped.all.each do |ticket|
      last_release = ticket.releases.first
      ticket.update_attribute(:last_release_at, last_release.created_at) if last_release
    end
  end

  def down
    remove_column :tickets, :last_release_at
  end
end

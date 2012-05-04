class LinkTicketsAndReleases < ActiveRecord::Migration
  def up
    create_table :releases_tickets, :id => false do |t|
      t.references :release, :ticket
    end
    
    add_index :releases_tickets, [:release_id, :ticket_id], :unique => true
    
    Release.all.each do |release|
      release.tickets.each do |ticket|
        ticket.releases << release
      end
    end
  end
  
  def down
    drop_table :releases_tickets
  end
end

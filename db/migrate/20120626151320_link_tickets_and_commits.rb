class LinkTicketsAndCommits < ActiveRecord::Migration
  def up
    create_table :commits_tickets, :id => false do |t|
      t.references :commit, :ticket
    end

    add_index :commits_tickets, [:commit_id, :ticket_id], :unique => true

    Commit.all.each do |commit|
      commit.send(:associate_tickets_with_self)
    end
  end

  def down
    drop_table :commits_tickets
  end
end

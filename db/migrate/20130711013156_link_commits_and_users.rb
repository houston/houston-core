class LinkCommitsAndUsers < ActiveRecord::Migration
  def up
    create_table :commits_users, :id => false do |t|
      t.references :commit, :user
    end

    add_index :commits_users, [:commit_id, :user_id], :unique => true

    commits_with_no_committers = {}

    pbar = ProgressBar.new("commits", Commit.count)
    Commit.find_each do |commit|
      committers = commit.identify_committers
      if committers.none?
        committer = "#{commit.committer} <#{commit.committer_email}>"
        commits_with_no_committers[committer] = commits_with_no_committers.fetch(committer, 0) + 1
      else
        commit.committers << committers
      end
      pbar.inc
    end
    pbar.finish



    puts "", "", "#{commits_with_no_committers.length} committer(s) could not be found: ", ""
    commits_with_no_committers.each do |committer, count|
      puts "  #{committer} (#{count})"
    end
  end

  def down
    drop_table :commits_users
  end
end

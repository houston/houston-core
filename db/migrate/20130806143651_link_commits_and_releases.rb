class LinkCommitsAndReleases < ActiveRecord::Migration
  def up
    create_table :commits_releases, :id => false do |t|
      t.references :commit, :release
    end

    add_index :commits_releases, [:commit_id, :release_id], :unique => true

    Commit.find_each do |commit|
      release = Release.find_by_id(commit.release_id) if commit.release_id
      commit.releases << release if release
    end
  end

  def down
    drop_table :commits_releases
  end
end

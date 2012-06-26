class ReplaceCommitterInfoWithAuthorInfo < ActiveRecord::Migration
  def up
    Commit.all.each do |commit|
      commit.update_attributes(
        committer:       commit.grit_commit.author.name,
        committer_email: commit.grit_commit.author.email)
    end
  end

  def down
  end
end

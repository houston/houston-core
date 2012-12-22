class ReplaceCommitterInfoWithAuthorInfo < ActiveRecord::Migration
  def up
    Commit.all.each do |commit|
      commit.update_attributes(
        committer:       commit.native_commit.author.name,
        committer_email: commit.native_commit.author.email) if commit.native_commit
    end
  end

  def down
  end
end

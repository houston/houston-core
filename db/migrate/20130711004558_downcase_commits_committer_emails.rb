class DowncaseCommitsCommitterEmails < ActiveRecord::Migration
  def up
    Commit.find_each do |commit|
      commit.update_column :committer_email, commit.committer_email.downcase if commit.committer_email
    end
  end

  def down
  end
end

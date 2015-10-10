class AddCommitterEmailToCommits < ActiveRecord::Migration
  def up
    add_column :commits, :committer_email, :string

    Commit.all.each do |commit|
      commit.update_attribute(:committer_email, commit.native_commit.committer.email) if commit.native_commit
    end
  end

  def down
    remove_column :commits, :committer_email
  end
end

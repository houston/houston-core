class RenameDeploysCommitToSha < ActiveRecord::Migration
  def up
    rename_column :deploys, :commit, :sha
    execute <<-SQL
      UPDATE deploys
         SET sha=commits.sha
        FROM commits
       WHERE deploys.commit_id=commits.id
    SQL
    change_column_null :deploys, :sha, false
  end

  def down
    change_column_null :deploys, :sha, true
    rename_column :deploys, :sha, :commit
  end
end

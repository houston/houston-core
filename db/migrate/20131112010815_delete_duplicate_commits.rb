class DeleteDuplicateCommits < ActiveRecord::Migration
  def up
    commits_by_sha = Hash.new { |hash, sha| hash[sha] = [] }
    select_rows("SELECT id, sha FROM commits").each do |(id, sha)|
      commits_by_sha[sha].push(id)
    end
    commits_by_sha.keep_if { |sha, ids| ids.length > 1 }

    puts "\e[33;1m#{Commit.count}\e[0;33m commits total; \e[1m#{commits_by_sha.values.flatten.count}\e[0;33m share \e[1m#{commits_by_sha.keys.count}\e[0;33m shas\e[0m"

    ids_to_delete = []
    commits_by_sha.each do |sha, ids|
      committer_ids = select_values("SELECT user_id FROM commits_users WHERE commit_id IN (#{ids.join(", ")})").uniq

      id_to_keep = ids.shift
      ids_to_delete.concat ids

      commit = Commit.find(id_to_keep)
      commit.committer_ids = User.where(id: committer_ids).pluck(:id)
    end

    execute "DELETE FROM commits WHERE commits.id IN (#{ids_to_delete.join(", ")})" if ids_to_delete.any?

    puts "\e[33;1m#{Commit.count}\e[0;33m commits left\e[0m"
  end

  def down
  end
end

class AddParentShaToCommits < ActiveRecord::Migration
  def up
    add_column :commits, :parent_sha, :string

    commits = Commit.reachable.reorder(nil)
    projects = Project.unretired
      .where(id: commits.pluck("DISTINCT project_id"))
      .reject { |project| project.repo.nil? }
    commits = commits.where(project_id: projects.map(&:id))

    # Do one `git pull` before starting
    puts "\e[94mSyncing commits...\e[0m"
    pbar = ProgressBar.new("projects", projects.count)
    projects.each do |project|
      project.commits.sync!
      pbar.inc
    end
    pbar.finish

    puts "\e[94mUpdating commits...\e[0m"
    pbar = ProgressBar.new("commits", commits.count)
    projects.each do |project|
      repo = project.repo
      conn = repo.send(:connection)
      project_commits = commits.where(project_id: project.id)

      project_commits.pluck(:sha).each do |sha|
        begin
          parent_sha = conn.lookup(sha).parent_oids[0]
          project_commits.where(sha: sha).update_all(parent_sha: parent_sha) if parent_sha
        rescue Rugged::OdbError
          project_commits.where(sha: sha).update_all(unreachable: true)
        end
        pbar.inc
      end
    end
    pbar.finish
  end

  def down
    remove_column :commits, :parent_sha
  end
end

class AddCommitIdToTestRuns < ActiveRecord::Migration
  def up
    add_column :test_runs, :commit_id, :integer

    # Do one `git pull` before starting
    puts "\e[94mSyncing commits...\e[0m"
    projects = Project.unretired.where(id: TestRun.reorder(nil).pluck("DISTINCT project_id"))
    pbar = ProgressBar.new("projects", projects.count)
    projects.find_each do |project|
      project.commits.sync!
      pbar.inc
    end
    pbar.finish

    puts "\e[94mAssociating commits with test runs...\e[0m"
    pbar = ProgressBar.new("test runs", TestRun.count)
    TestRun.pluck(:project_id, :sha, :id).each do |project_id, sha, id|
      commit = Commit.where(project_id: project_id).with_sha_like(sha).pluck(:id, :sha)[0]
      TestRun.where(id: id).update_all(commit_id: commit[0], sha: commit[1]) if commit
      pbar.inc
    end
    pbar.finish

    puts "\e[33;1m#{TestRun.where(commit_id: nil).count}\e[0;33m out of \e[1m#{TestRun.count}\e[0;33m test runs aren't associated with a commit\e[0m"
  end

  def down
    remove_column :test_runs, :commit_id
  end
end

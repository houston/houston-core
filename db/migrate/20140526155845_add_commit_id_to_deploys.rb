class AddCommitIdToDeploys < ActiveRecord::Migration
  def up
    add_column :deploys, :commit_id, :integer

    # Do one `git pull` before starting
    puts "syncing commits"
    pbar = ProgressBar.new("projects", Deploy.count)
    Project.unretired.find_each do |project|
      project.commits.sync!
      pbar.inc
    end
    pbar.finish

    pbar = ProgressBar.new("deploys", Deploy.count)
    Deploy.includes(:project).find_each do |deploy|
      pbar.inc
      next unless deploy.project

      sha = deploy.read_attribute(:commit)
      commit = deploy.project.commits.find_by_sha(sha)
      deploy.update_column :commit_id, commit.id if commit
    end
    pbar.finish

    puts "\e[33;1m#{Deploy.where(commit_id: nil).count}\e[0;33m out of \e[1m#{Deploy.count}\e[0;33m deploys aren't associated with a commit\e[0m"
  end

  def down
    remove_column :deploys, :commit_id
  end
end

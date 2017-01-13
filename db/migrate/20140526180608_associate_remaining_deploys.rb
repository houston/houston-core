class AssociateRemainingDeploys < ActiveRecord::Migration
  def up
    @invalid_shas = 0

    pbar = ProgressBar.new("deploys", Deploy.where(commit_id: nil).count)
    Deploy.includes(:project).where(commit_id: nil).find_each do |deploy|
      pbar.inc
      next unless deploy.project
      next if deploy.project.retired?

      sha = deploy.read_attribute(:commit)
      commit = find_commit(deploy.project, sha)
      deploy.update_column :commit_id, commit.id if commit
    end
    pbar.finish

    puts "\e[31;1m#{@invalid_shas}\e[0;31m invalid shas\e[0m"
    puts "\e[33;1m#{Deploy.where(commit_id: nil).count}\e[0;33m out of \e[1m#{Deploy.count}\e[0;33m deploys aren't associated with a commit\e[0m"
  end

private

  def find_commit(project, sha)
    project.find_commit_by_sha(sha)
  rescue Houston::Adapters::VersionControl::CommitNotFound
    nil
  rescue Houston::Adapters::VersionControl::InvalidShaError
    @invalid_shas += 1
    nil
  end

end

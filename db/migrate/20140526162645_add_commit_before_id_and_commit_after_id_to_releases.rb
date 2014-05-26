class AddCommitBeforeIdAndCommitAfterIdToReleases < ActiveRecord::Migration
  def up
    add_column :releases, :commit_before_id, :integer
    add_column :releases, :commit_after_id, :integer
    
    pbar = ProgressBar.new("releases", Release.count)
    Release.includes(:project).find_each do |release|
      pbar.inc
      next unless release.project
      
      sha0 = release.read_attribute(:commit0)
      sha1 = release.read_attribute(:commit1)
      commit0 = release.project.commits.find_by_sha sha0
      commit1 = release.project.commits.find_by_sha sha1
      release.update_column :commit_before_id, commit0.id if commit0
      release.update_column :commit_after_id, commit1.id if commit1
    end
    pbar.finish
    
    puts "\e[33;1m#{Release.where(commit_before_id: nil).count}\e[0;33m out of \e[1m#{Release.count}\e[0;33m release don't have a commit_before\e[0m"
    puts "\e[33;1m#{Release.where(commit_after_id: nil).count}\e[0;33m out of \e[1m#{Release.count}\e[0;33m release don't have a commit_after\e[0m"
  end
  
  def down
    remove_column :releases, :commit_before_id
    remove_column :releases, :commit_after_id
  end
end

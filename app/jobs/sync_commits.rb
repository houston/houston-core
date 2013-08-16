class SyncCommits
  
  
  def self.run!(options={})
    new.run!(options)
  rescue
    binding.pry if binding.respond_to?(:pry)
  end
  
  def run!(options={})
    Project.find_each do |project|
      project.repo.refresh! # i.e. git remote update
      sync_commits_for_project! project, options
    end
  end
  
  def sync_commits_for_project!(project, options={})
    Commit.benchmark("[commits:sync] synced commits for #{project.name}") do
      existing_commits = project.commits.pluck(:sha)
      expected_commits = project.repo.all_commits
      
      create_missing_commits_for_project! project, options, expected_commits - existing_commits
      flag_unreachable_commits_for_project! project, options, existing_commits - expected_commits
    end
  end
  
  def create_missing_commits_for_project!(project, options, missing_commits)
    return if missing_commits.none?
    
    with_progress = options.fetch(:with_progress, false)
    
    pbar = ProgressBar.new(project.slug, Commit.count) if with_progress
    missing_commits.each do |sha|
      native_commit = project.repo.native_commit(sha)
      project.commits.from_native_commit(native_commit).save!
      pbar.inc if with_progress
    end
    pbar.finish if with_progress
    
    Rails.logger.info "[commits:sync] #{missing_commits.length} new commits for #{project.name}"
  end
  
  def flag_unreachable_commits_for_project!(project, options, unreachable_commits)
    return if unreachable_commits.none?
    
    project.commits.where(sha: unreachable_commits).update_all(unreachable: true)
    
    Rails.logger.info "[commits:sync] #{unreachable_commits.length} unreachable commits for #{project.name}"
  end
  
  
end

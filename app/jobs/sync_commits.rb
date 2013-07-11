class SyncCommits
  
  
  def self.run!(options={})
    new.run!(options)
  rescue
    binding.pry if binding.respond_to?(:pry)
  end
  
  def run!(options={})
    Project.find_each do |project|
      project.repo.refresh! # i.e. git remote update
      create_missing_commits_for_project! project, options
    end
  end
  
  def create_missing_commits_for_project!(project, options={})
    with_progress = options.fetch(:with_progress, false)
    
    existing_commits = project.commits.pluck(:sha)
    expected_commits = project.repo.all_commits
    missing_commits = expected_commits - existing_commits
    extra_commits = existing_commits - expected_commits
    
    Rails.logger.info "[commits:sync] #{extra_commits.length} extra commits for #{project.name}"
    
    return if missing_commits.none?
    
    Commit.benchmark("[commits:sync] Sync #{missing_commits.length} commits for #{project.name}") do
      pbar = ProgressBar.new(project.slug, Commit.count) if with_progress
      missing_commits.each do |sha|
        native_commit = project.repo.native_commit(sha)
        project.commits.from_native_commit(native_commit).save!
        pbar.inc if with_progress
      end
      pbar.finish if with_progress
    end
  end
  
  
end

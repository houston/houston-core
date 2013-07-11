class AddAuthoredAtToCommits < ActiveRecord::Migration
  def up
    add_column :commits, :authored_at, :timestamp
    
    Commit.reset_column_information
    Project.find_each do |project|
      project.repo.refresh! # i.e. git remote update
    end
    
    missing_commits = []
    destroyed_commits = 0
    
    pbar = ProgressBar.new("commits", Commit.count)
    Commit.find_each do |commit|
      
      if commit.project.nil?
        commit.destroy
        destroyed_commits += 1
      else
        begin
          commit.update_column :authored_at, commit.native_commit.authored_at
        rescue Houston::Adapters::VersionControl::CommitNotFound
          commit.destroy
          missing_commits << commit
        end
      end
      
      pbar.inc
    end
    pbar.finish
    
    
    change_column_null :commits, :authored_at, false
    
    
    puts "", "", ""
    missing_commits.each do |commit|
      puts "#{commit.project.slug.ljust(12)} #{commit.sha} #{commit.release_id.to_s.rjust(5)} #{commit.message}"
    end
    puts "", "", "#{missing_commits.length} commits were not found in the repo and were destroyed"
    puts "#{destroyed_commits} commits had no project and were destroyed"
  end
  
  def down
    remove_column :commits, :authored_at
  end
end

class AddAuthoredAtToCommits < ActiveRecord::Migration
  def up
    add_column :commits, :authored_at, :timestamp

    Commit.reset_column_information
    Project.find_each do |project|
      project.repo.refresh! # i.e. git remote update
    end

    missing_commits = []

    pbar = ProgressBar.new("commits", Commit.count)
    Project.unscoped do
      Project.find_each do |project|
        project.commits.each do |commit|

          begin
            native_commit = project.repo.native_commit(commit.sha)
            unless native_commit
              commit.delete
              missing_commits << commit
              next
            end
            commit.update_column :authored_at, native_commit.authored_at
          rescue Houston::Adapters::VersionControl::CommitNotFound
            commit.delete
            missing_commits << commit
          end

          pbar.inc
        end
      end
    end
    pbar.finish


    change_column_null :commits, :authored_at, false


    puts "", "", ""
    Project.unscoped do
      missing_commits.each do |commit|
        puts "#{commit.project.slug.ljust(12)} #{commit.sha} #{commit.release_id.to_s.rjust(5)} #{commit.message}"
      end
    end
    puts "", "", "#{missing_commits.length} commits were not found in the repo and were destroyed"
  end

  def down
    remove_column :commits, :authored_at
  end
end

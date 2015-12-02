require "progressbar"

class AddHeadShaToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :head_sha, :string

    projects = Project.unretired
    pbar = ProgressBar.new "projects", projects.count

    projects.find_each do |project|
      pbar.inc
      next unless project.repo.exists?

      sha = project.repo.branch("master")
      project.update_column :head_sha, sha
    end

    pbar.finish
  end

  def down
    remove_column :projects, :head_sha
  end
end

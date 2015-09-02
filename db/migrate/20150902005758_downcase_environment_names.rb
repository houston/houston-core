class DowncaseEnvironmentNames < ActiveRecord::Migration
  def up
    deploys = Deploy.all
    pbar = ProgressBar.new("deploys", deploys.count)
    deploys.find_each do |deploy|
      deploy.update_column :environment_name, deploy.environment_name.downcase
      pbar.inc
    end
    pbar.finish

    releases = Release.all
    pbar = ProgressBar.new("releases", releases.count)
    releases.find_each do |release|
      release.update_column :environment_name, release.environment_name.downcase
      pbar.inc
    end
    pbar.finish
  end
end

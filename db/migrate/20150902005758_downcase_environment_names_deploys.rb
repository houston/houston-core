class DowncaseEnvironmentNamesDeploys < ActiveRecord::Migration
  def up
    deploys = Deploy.all
    pbar = ProgressBar.new("deploys", deploys.count)
    deploys.find_each do |deploy|
      deploy.update_column :environment_name, deploy.environment_name.downcase
      pbar.inc
    end
    pbar.finish
  end
end

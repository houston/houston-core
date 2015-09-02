class PopulateDeploysUser < ActiveRecord::Migration
  def up
    deploys = Deploy.where("deployer IS NOT NULL")
    pbar = ProgressBar.new("deploys", deploys.count)
    user_id_by_email = Hash.new { |hash, email| hash[email] = User.find_by_email_address(email).try :id }
    deploys.find_each do |deploy|
      user_id = user_id_by_email[deploy.deployer]
      deploy.update_column :user_id, user_id if user_id
      pbar.inc
    end
    pbar.finish
  end
end

class AddCommitIdToDeploys < ActiveRecord::Migration
  def up
    add_column :deploys, :commit_id, :integer
    
    Deploy.includes(:project).find_each do |deploy|
      next unless deploy.project
      deploy.sha = deploy.read_attribute(:commit)
      commit = deploy.send :identify_commit
      deploy.update_column :commit_id, commit.id if commit
    end
    
    puts "\e[33;1m#{Deploy.where(commit_id: nil).count}\e[0;33m out of \e[1m#{Deploy.count}\e[0;33m deploys aren't associated with a commit\e[0m"
  end
  
  def down
    remove_column :deploys, :commit_id
  end
end

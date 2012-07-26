class LinkProjectsAndMaintainers < ActiveRecord::Migration
  def up
    create_table :projects_maintainers, :id => false do |t|
      t.references :project, :user
    end
    
    add_index :projects_maintainers, [:project_id, :user_id], :unique => true
    
    admins = User.administrators
    Project.all.each do |project|
      admins.each do |admin|
        project.maintainers << admin
      end
    end
  end

  def down
    drop_table :projects_maintainers
  end
end

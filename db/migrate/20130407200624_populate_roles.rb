class PopulateRoles < ActiveRecord::Migration
  def up
    developer_ids = User.where(role: "Developer").pluck(:id)
    tester_ids = User.where(role: "Tester").pluck(:id)
    participant_ids = developer_ids + tester_ids
    
    Project.find_each do |project|
      maintainer_ids = users_that_maintain(project)
      follower_ids = users_that_follow(project)
      
      maintainer_ids.each do |user_id|
        project.add_teammate user_id, "Maintainer"
      end
      
      (developer_ids - maintainer_ids).each do |user_id|
        project.add_teammate user_id, "Contributor"
      end
      
      tester_ids.each do |user_id|
        project.add_teammate user_id, "Tester"
      end
      
      (follower_ids - participant_ids).each do |user_id|
        project.add_teammate user_id, "Follower"
      end
    end
  end
  
  def down
    Role.delete_all
  end
  
  def users_that_follow(project)
    sql = "SELECT DISTINCT user_id FROM user_notifications WHERE project_id=#{project.id}"
    User.connection.select_values(sql).map(&:to_i)
  end
  
  def users_that_maintain(project)
    sql = "SELECT DISTINCT user_id FROM projects_maintainers WHERE project_id=#{project.id}"
    User.connection.select_values(sql).map(&:to_i)
  end
  
end

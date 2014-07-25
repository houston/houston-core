class CreateSprintsTasks < ActiveRecord::Migration
  def up
    create_join_table :sprints, :tasks do |t|
      t.index [:sprint_id, :task_id], unique: true
    end
    
    Task.where(Task.arel_table[:sprint_id].not_eq(nil)).pluck(:id, :sprint_id).each do |task_id, sprint_id|
      SprintTask.create(task_id: task_id, sprint_id: sprint_id)
    end
    
    puts "\e[34m#{SprintTask.count} tasks put into sprints\e[0m"
  end
  
  def down
    drop_join_table :sprints, :tasks
  end
end

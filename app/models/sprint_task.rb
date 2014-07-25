class SprintTask < ActiveRecord::Base
  self.table_name = "sprints_tasks"
  
  belongs_to :sprint
  belongs_to :task
end

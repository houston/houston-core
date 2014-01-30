class KanbanController < ApplicationController
  
  
  def index
    @title = "Kanban"
    
    @projects = Project.unretired
  end
  
  
end

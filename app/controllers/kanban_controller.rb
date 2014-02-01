class KanbanController < ApplicationController
  
  
  def index
    @title = "Kanban"
    
    @projects = followed_projects
  end
  
  
end

class KanbanController < ApplicationController
  
  
  def index
    @title = "Kanban"
    
    @projects = Project.with_ticket_tracking
  end
  
  
end

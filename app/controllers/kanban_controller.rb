class KanbanController < ApplicationController
  
  
  def index
    @title = "Kanban"
    
    @projects = Project.with_ticket_tracker
  end
  
  
end

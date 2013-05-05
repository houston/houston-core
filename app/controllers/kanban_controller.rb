class KanbanController < ApplicationController
  
  
  def index
    @title = "Kanban"
    
    @projects = Project.where(ticket_tracker_name: "Unfuddle")
  end
  
  
end

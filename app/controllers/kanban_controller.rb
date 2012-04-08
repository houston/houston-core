class KanbanController < ApplicationController
  
  
  def index
    @projects = Project.where("unfuddle_id IS NOT NULL")
  end
  
  
end

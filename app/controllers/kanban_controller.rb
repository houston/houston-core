class KanbanController < ApplicationController
  
  
  def index
    @projects = Project.where("unfuddle_id IS NOT NULL")
  end
  
  
  def show
    @project = Project.find_by_slug!(params[:slug])
  end
  
  
end

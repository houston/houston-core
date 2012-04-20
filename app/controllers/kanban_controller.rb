class KanbanController < ApplicationController
  before_filter :find_project, :except => [:index]
  
  
  def index
    @projects = Project.where("unfuddle_id IS NOT NULL")
  end
  
  
  def show
  end
  
  
  def queue
    render :json => TicketPresenter.new(@project.tickets_in_queue(params[:queue]))
  end
  
  
private
  
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
  
end

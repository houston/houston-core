class Unfuddle::ProjectsController < UnfuddleController
  before_filter :find_project, :except => [:index]
  
  def index
    render_from_unfuddle "/projects"
  end
  
  def show
    render_from_unfuddle "/projects/#{@project.unfuddle_id}"
  end
  
  def in_development
    render :json => @project.find_tickets(@project.in_development_query, :status => :accepted)
  end
  
  def staged_for_testing
    render :json => @project.find_tickets(@project.staged_for_testing_query, :status => :resolved)
  end
  
  def in_testing
    render :json => @project.find_tickets(@project.in_testing_query, :status => :resolved)
  end
  
  def staged_for_release
    render :json => @project.find_tickets(@project.staged_for_release_query, :status => :closed, :resolution => :fixed)
  end
  
private
  
  def find_project
    @project = Project.find_by_unfuddle_id!(params[:id])
  end
  
end

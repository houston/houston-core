class ProjectExceptionsController < ApplicationController
  before_filter :find_project
  attr_reader :project
  
  
  def merge_several
    respond_with project.error_tracker.merge_problems(params[:problems])
  end
  
  
  def unmerge_several
    respond_with project.error_tracker.unmerge_problems(params[:problems])
  end
  
  
  def delete_several
    respond_with project.error_tracker.delete_problems(params[:problems])
  end
  
  
private
  
  def respond_with(response)
    if response.status == 200
      flash[:notice] = response.body
      head :ok
    else
      render text: response.body, status: response.status
    end
  end
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
end

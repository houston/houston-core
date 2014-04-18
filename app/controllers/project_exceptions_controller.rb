class ProjectExceptionsController < ApplicationController
  before_filter :find_project
  attr_reader :project
  
  
  def merge_several
    head project.error_tracker.merge_problems(params[:problems])
  end
  
  
  def unmerge_several
    head project.error_tracker.unmerge_problems(params[:problems])
  end
  
  
  def delete_several
    head project.error_tracker.delete_problems(params[:problems])
  end
  
  
private
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
end

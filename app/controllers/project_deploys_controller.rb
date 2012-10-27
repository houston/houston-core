class ProjectDeploysController < ApplicationController
  
  
  def create
    @project = Project.find_by_slug(params[:project])
    unless @project
      head 404
      return
    end
    
    @environment = @project.environments \
      .where(slug: params[:environment]) \
      .first_or_create!
    
    Deploy.create!({
      project: @project,
      environment: @environment,
      commit: params[:commit]
    })
    
    head 200
  end
  
  
end

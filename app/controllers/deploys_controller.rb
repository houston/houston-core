class DeploysController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  
  def create
    @project = Project.find_by_slug(params[:project_id])
    unless @project
      render text: "A project with the slug '#{params[:project_id]}' could not be found", status: 404
      return
    end
    
    @environment = params[:environment]
    unless Houston.config.environments.member?(@environment)
      render text: "Houston is not configured to recognize an environment with the name '#{@environment}'", status: 404
      return
    end
    
    Deploy.create!({
      project: @project,
      environment_name: @environment,
      commit: params[:commit]
    })
    
    head 200
  end
  
  
end

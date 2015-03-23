class DeploysController < ApplicationController
  include AnsiHelper
  skip_before_filter :verify_authenticity_token
  
  
  def create
    @project = Project.find_by_slug(params[:project_id])
    unless @project
      render text: "A project with the slug '#{params[:project_id]}' could not be found", status: 404
      return
    end
    
    @environment = params.fetch(:environment, "").titleize
    unless Houston.config.environments.member?(@environment)
      render text: "Houston is not configured to recognize an environment with the name '#{@environment}'", status: 404
      return
    end
    
    sha = params[:commit] || params[:head_long] || params[:head]
    branch = params[:branch]
    deployer = params[:deployer] || params[:user]
    milliseconds = params[:duration]
    
    Deploy.create!(
      project: @project,
      environment_name: @environment,
      sha: sha,
      branch: branch,
      deployer: deployer,
      duration: milliseconds,
      completed_at: Time.now)
    
    head 200
  end
  
  
  def show
    @project = Project.find_by_slug! params[:project_id]
    @deploy = @project.deploys.find params[:id]
    
    if request.format.json?
      render json: { completed: @deploy.completed?, output: ansi_to_html(@deploy.output) }
    end
  end
  
  
end

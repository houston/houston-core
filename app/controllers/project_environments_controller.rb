class ProjectEnvironmentsController < ApplicationController
  include UrlHelper
  before_filter :find_project
  before_filter :find_environment, :only => [:show, :edit, :update, :destroy, :post_receive]
  load_resource :environment, :find_by => :slug, :through => :project
  authorize_resource :environment
  
  def index
    @environments = @project.environments.all
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @environments }
    end
  end
  
  def post_receive
    @release = @environment.releases.new(commit0: @environment.last_commit, commit1: params[:commit])
    
    if @release.can_read_commits?
      @release.load_commits!
      @release.load_tickets!
      @release.build_changes_from_commits
    end
    
    @release.maintainers.each do |maintainer|
      NotificationMailer.on_post_receive(@release, maintainer).deliver!
    end
  rescue Timeout::Error
    render text: "Couldn't get a response from the mail server. Is everything OK?", status: 500
  end
  
  def show
    @releases = @environment.releases
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @environment }
    end
  end
  
  def new
    @environment = @project.environments.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @environment }
    end
  end
  
  def edit
  end
  
  def create
    @environment = @project.environments.new(params[:environment])
    
    respond_to do |format|
      if @environment.save
        format.html { redirect_to @environment, notice: 'Environment was successfully created.' }
        format.json { render json: @environment, status: :created, location: @environment }
      else
        format.html { render action: "new" }
        format.json { render json: @environment.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @environment.update_attributes(params[:environment])
        format.html { redirect_to @environment, notice: 'Environment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @environment.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @environment.destroy
    
    respond_to do |format|
      format.html { redirect_to project_environments_url(@project) }
      format.json { head :no_content }
    end
  end
  
  
private
  
  
  def find_project
    @project = Project.find_by_slug!(params[:project_id])
  end
  
  def find_environment
    @environment = @project.environments.find_by_slug!(params[:id])
  end
  
  
end

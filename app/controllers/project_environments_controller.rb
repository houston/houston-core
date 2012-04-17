class ProjectEnvironmentsController < ApplicationController
  include UrlHelper
  before_filter :find_project
  load_resource :environment, :find_by => :slug, :through => :project
  authorize_resource :environment
  
  # GET /environments
  # GET /environments.json
  def index
    @environments = @project.environments.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @environments }
    end
  end

  # GET /environments/1
  # GET /environments/1.json
  def show
    @environment = @project.environments.find_by_slug!(params[:id])
    @releases = @environment.releases

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @environment }
    end
  end

  # GET /environments/new
  # GET /environments/new.json
  def new
    @environment = @project.environments.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @environment }
    end
  end

  # GET /environments/1/edit
  def edit
    @environment = @project.environments.find_by_slug!(params[:id])
  end

  # POST /environments
  # POST /environments.json
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

  # PUT /environments/1
  # PUT /environments/1.json
  def update
    @environment = @project.environments.find_by_slug!(params[:id])

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

  # DELETE /environments/1
  # DELETE /environments/1.json
  def destroy
    @environment = @project.environments.find_by_slug!(params[:id])
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
  
end

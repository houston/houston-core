class ProjectsController < ApplicationController
  before_filter :convert_maintainers_attributes_to_maintainer_ids
  load_resource :find_by => :slug # will use find_by_permalink!(params[:id])
  authorize_resource
  
  # GET /projects
  # GET /projects.json
  def index
    @title = "Projects"
    @projects = Project.reorder("category ASC, name ASC")
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    redirect_to project_dashboard_path(@project)
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @title = "New Project"
    
    @project = Project.new
    @project.maintainers << current_user if @project.maintainers.none?
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find_by_slug!(params[:id])
    @project.maintainers << current_user if @project.maintainers.none?
    
    @title = "#{@project.name}: Edit"
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(params[:project])

    respond_to do |format|
      if @project.save
        format.html { redirect_to projects_path, notice: 'Project was successfully created.' }
        format.json { render json: @project, status: :created, location: @project }
      else
        format.html { render action: "new" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    @project = Project.find_by_slug!(params[:id])
    
    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to projects_path, notice: 'Project was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end
  
  
  # PUT /projects/1/retire
  def retire
    @project = Project.find_by_slug!(params[:id])
    @project.retire!
    redirect_to projects_path, notice: "#{@project.name} was successfully retired."
  end
  
  
  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project = Project.find_by_slug!(params[:id])
    @project.destroy
    
    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :no_content }
    end
  end
  
  
private
  
  
  def convert_maintainers_attributes_to_maintainer_ids
    attributes = params.fetch(:project, {}).delete(:maintainers_attributes)
    if attributes
      params[:project][:maintainer_ids] = attributes.values.select { |attributes| attributes[:_destroy] != "1" }.map { |attributes| attributes[:id].to_i }
    end
  end
  
  
end

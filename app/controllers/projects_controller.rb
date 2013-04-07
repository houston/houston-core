class ProjectsController < ApplicationController
  before_filter :convert_maintainers_attributes_to_maintainer_ids
  load_resource :find_by => :slug # will use find_by_permalink!(params[:id])
  authorize_resource
  
  
  def index
    @title = "Projects"
    @projects = Project.all
  end
  
  
  def show
    redirect_to project_dashboard_path(@project)
  end
  
  
  def new
    @title = "New Project"
    
    @project = Project.new
    @project.maintainers << current_user if @project.maintainers.none?
  end
  
  
  def edit
    @project = Project.find_by_slug!(params[:id])
    @project.roles.build if @project.roles.none?
    
    @title = "#{@project.name}: Edit"
  end
  
  
  def create
    @project = Project.new(params[:project])
    
    if @project.save
      redirect_to projects_path, notice: 'Project was successfully created.'
    else
      render action: "new"
    end
  end
  
  
  def update
    @project = Project.find_by_slug!(params[:id])
    
    if @project.update_attributes(params[:project])
      redirect_to projects_path, notice: 'Project was successfully updated.'
    else
      render action: "edit"
    end
  end
  
  
  def retire
    @project = Project.find_by_slug!(params[:id])
    @project.retire!
    redirect_to projects_path, notice: "#{@project.name} was successfully retired."
  end
  
  
  def destroy
    @project = Project.find_by_slug!(params[:id])
    @project.destroy
    
    redirect_to projects_url
  end
  
  
private
  
  
  def convert_maintainers_attributes_to_maintainer_ids
    attributes = params.fetch(:project, {}).delete(:maintainers_attributes)
    if attributes
      params[:project][:maintainer_ids] = attributes.values.select { |attributes| attributes[:_destroy] != "1" }.map { |attributes| attributes[:id].to_i }
    end
  end
  
  
end

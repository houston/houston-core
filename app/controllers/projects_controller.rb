class ProjectsController < ApplicationController
  before_filter :convert_maintainers_attributes_to_maintainer_ids, only: [:create, :update]
  load_resource :find_by => :slug # will use find_by_permalink!(params[:id])
  authorize_resource
  
  
  def index
    @title = "Projects"
    @projects = Project \
      .includes(:owners)
      .includes(:maintainers)
      .unretired
      .map { |project| ProjectDependencies.new(project) }
    @test_runs = TestRun.most_recent.index_by(&:project_id)
    @releases = Release.most_recent.index_by { |release| [release.project_id, release.environment_name] }
  end
  
  
  def show
    redirect_to projects_path
  end
  
  
  def new
    @title = "New Project"
    
    @project = Project.new
    @project.roles.build(user: current_user) if @project.roles.none?
  end
  
  
  def edit
    @project = Project.find_by_slug!(params[:id])
    @project.roles.build(user: current_user) if @project.roles.none?
    
    @title = "Edit #{@project.name}"
  end
  
  
  def create
    @project = Project.new(project_attributes)
    
    if @project.save
      redirect_to projects_path, notice: 'Project was successfully created.'
    else
      flash.now[:error] = @project.errors[:base].join("\n")
      render action: "new"
    end
  end
  
  
  def update
    @project = Project.find_by_slug!(params[:id])
    
    if @project.update_attributes(project_attributes)
      redirect_to projects_path, notice: 'Project was successfully updated.'
    else
      flash.now[:error] = @project.errors[:base].join("\n")
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
  
  
  def project_attributes
    attrs = params[:project]
    attrs[:selected_features] ||= []
    attrs
  end
  
  
  def convert_maintainers_attributes_to_maintainer_ids
    attributes = params.fetch(:project, {}).delete(:maintainers_attributes)
    if attributes
      params[:project][:maintainer_ids] = attributes.values.select { |attributes| attributes[:_destroy] != "1" }.map { |attributes| attributes[:id].to_i }
    end
  end
  
  
end

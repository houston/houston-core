class ProjectsController < ApplicationController
  before_filter :convert_maintainers_attributes_to_maintainer_ids
  load_resource :find_by => :slug # will use find_by_permalink!(params[:id])
  authorize_resource
  
  # GET /projects
  # GET /projects.json
  def index
    @title = "Projects"
    @projects = Project.scoped
    
    gems = cache "rubygems/rails/#{Date.today.strftime('%Y%m%d')}/json" do
      response = Faraday.get("https://rubygems.org/api/v1/versions/rails.json")
      JSON.load(response.body)
    end
    
    rails_versions = gems.map { |hash| Gem::Version.new (hash["number"]) }.sort.reverse
    @rails_minor_versions = rails_versions.map { |version| version.to_s[/\d+\.\d+/] }.uniq
    @rails_version_latest = rails_versions.first
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project = Project.find_by_slug!(params[:id])
    @tickets = @project.ticket_system.find_tickets("status-neq-closed")
    
    dependencies = %w{rails devise}
    @dependency_versions = {}
    dependencies.each do |dependency|
      
      @dependency_versions[dependency] = cache "rubygems/#{dependency}/#{Date.today.strftime('%Y%m%d')}/info" do
        
        gems = cache "rubygems/#{dependency}/#{Date.today.strftime('%Y%m%d')}/json" do
          response = Faraday.get("https://rubygems.org/api/v1/versions/#{dependency}.json")
          JSON.load(response.body)
        end
        
        versions = gems.map { |hash| Gem::Version.new (hash["number"]) }.sort.reverse
        stringified_versions = versions.map(&:to_s)
        latest_version = versions.first
        current_minor_version = stringified_versions.first[/\d+\.\d+/]
        rx = /^#{current_minor_version}\.\d+$/
        patches = stringified_versions.select { |version| version =~ rx }
        
        {
          name: dependency.titleize,
          versions: versions,
          minor_versions: stringified_versions.map { |version| version[/\d+\.\d+/] }.uniq,
          patches: patches,
          latest: latest_version
        }
      end
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @title = "New Project"
    
    @project = Project.new
    @project.environments.build(Rails.configuration.default_environments) if @project.environments.none?
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

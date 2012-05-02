class ReleasesController < ApplicationController
  include UrlHelper
  before_filter :get_project_and_environment
  load_and_authorize_resource
  
  # GET /releases
  # GET /releases.json
  def index
    @releases = @environment.releases.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @releases }
    end
  end

  # GET /releases/1
  # GET /releases/1.json
  def show
    @release = @environment.releases.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @release }
    end
  end

  # GET /releases/new
  # GET /releases/new.json
  def new
    @commit0 = params[:commit0] || @environment.last_commit
    @commit1 = params[:commit1] || params[:commit]
    @release = @environment.releases.new(commit0: @commit0, commit1: @commit1)
    if @release.can_read_commits?
      @release.load_commits!
      @release.load_tickets!
      @release.build_changes_from_commits
    end
    if @release.changes.none?
      render :template => "releases/new_pick_commit"
    else
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @release }
      end
    end
  end

  # GET /releases/1/edit
  def edit
    @release = @environment.releases.find(params[:id])
    
    if params[:recreate]
      @release.changes.each { |change| change._destroy = true }
      if @release.can_read_commits?
        @release.load_commits!
        @release.load_tickets!
        @release.build_changes_from_commits
      end
    end
    
    @release.changes.build if @release.changes.select { |change| !change._destroy }.none?
  end

  # POST /releases
  # POST /releases.json
  def create
    @release = @environment.releases.new(params[:release])

    respond_to do |format|
      if @release.save
        format.html { redirect_to @release, notice: 'Release was successfully created.' }
        format.json { render json: @release, status: :created, location: @release }
      else
        format.html { render action: "new" }
        format.json { render json: @release.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /releases/1
  # PUT /releases/1.json
  def update
    @release = @environment.releases.find(params[:id])

    respond_to do |format|
      if @release.update_attributes(params[:release])
        format.html { redirect_to @release, notice: 'Release was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @release.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /releases/1
  # DELETE /releases/1.json
  def destroy
    @release = @environment.releases.find(params[:id])
    @release.destroy

    respond_to do |format|
      format.html { redirect_to releases_url }
      format.json { head :no_content }
    end
  end
  
private
  
  def get_project_and_environment
    @project = Project.find_by_slug!(params[:project_id])
    @environment = @project.environments.find_by_slug!(params[:environment_id])
  end
  
end

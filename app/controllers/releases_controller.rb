class ReleasesController < ApplicationController
  include UrlHelper
  before_filter :get_project_and_environment
  before_filter :get_deployment_and_recipients, only: [:new, :create]
  load_and_authorize_resource
  
  # GET /releases
  # GET /releases.json
  def index
    @title = "#{@project.name}: Releases"
    @title << " (#{@environment.name})" if @environment
    
    @releases = @environment ? @environment.releases.all : []
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @releases }
    end
  end

  # GET /releases/1
  # GET /releases/1.json
  def show
    @release = @environment.releases.find(params[:id])
    
    @title = "#{@project.name}: #{@release.name}"
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @release }
    end
  end

  # GET /releases/new
  # GET /releases/new.json
  def new
    @title = "#{@project.name}: New Release (#{@environment.name})"
    
    @deploy = Deploy.find_by_id(params[:deploy_id])
    @commit0 = params[:commit0] || @environment.last_commit
    @commit1 = @deploy.try(:commit) || params[:commit1] || params[:commit]
    @release = @environment.releases.new(commit0: @commit0, commit1: @commit1, deploy: @deploy)
    
    if @project.repo.nil?
      respond_to do |format|
        format.html { render template: "releases/invalid_repo" }
        format.json { head 422 }
      end
      return
    end
    
    if @release.can_read_commits?
      @release.load_commits!
      @release.load_tickets!
      @release.build_changes_from_commits
      
      noun = @release.changes.length == 1 ? "change has" : "changes have"
      @release.message = "Hey everyone!\n\n#{@release.changes.length} #{noun} been deployed to #{@release.environment.name}."
    end
    respond_to do |format|
      format.html do
        if request.headers['X-PJAX']
          render template: "releases/_new_release", layout: false
        else
          render
        end
      end
      format.json { render json: @release }
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
    @release.valid?
  end

  # POST /releases
  # POST /releases.json
  def create
    @release = @environment.releases.new(params[:release])
    @release.user = current_user
    
    if @release.save
      @release.update_tickets_in_unfuddle! if params[:update_tickets_in_unfuddle]
      ViewMailer.release(@release).deliver! if params[:send_release_email]
      
      redirect_to @release, notice: 'Release was successfully created.'
    else
      @commit0 = @release.commit0
      @commit1 = @release.commit1
      
      if @release.can_read_commits?
        @release.load_commits!
        @release.load_tickets!
      end
      
      render action: "new"
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
    @environment = @project.environments.find_by_slug(params[:environment_id]) || @project.environments.first
  end
  
  def get_deployment_and_recipients
    if @environment.slug == "dev" # <-- knowledge about environments!
      @deployment = "Testing"
    elsif @environment.slug == "master"
      @deployment = "Production"
    end
  end
  
end

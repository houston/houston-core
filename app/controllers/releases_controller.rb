class ReleasesController < ApplicationController
  include UrlHelper
  before_filter :get_project_and_environment
  load_and_authorize_resource
  
  def index
    @title = "#{@project.name}: Releases"
    @title << " (#{@environment})" if @environment
  end
  
  def show
    @release = @releases.find(params[:id])
    @title = "#{@project.name}: #{@release.name}"
  end
  
  def new
    @title = "#{@project.name}: New Release (#{@environment})"
    
    @deploy = Deploy.find_by_id(params[:deploy_id])
    @commit0 = params.fetch :commit0, @releases.most_recent_commit
    @commit1 = params.fetch :commit1, @deploy.try(:commit)
    @release = @releases.new(commit0: @commit0, commit1: @commit1, deploy: @deploy)
    
    if @project.repo.nil?
      render template: "releases/invalid_repo"
      return
    end
    
    if @release.can_read_commits?
      @release.load_commits!
      @release.load_tickets!
      @release.build_changes_from_commits
      
      noun = @release.changes.length == 1 ? "change has" : "changes have"
      @release.message = "Hey everyone!\n\n#{@release.changes.length} #{noun} been deployed to #{@release.environment_name}."
    end
    
    if request.headers['X-PJAX']
      render template: "releases/_new_release", layout: false
    else
      render
    end
  end

  def edit
    @release = @releases.find(params[:id])
    
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

  def create
    @release = @releases.new(params[:release])
    @release.user = current_user
    
    if @release.save
      @release.update_tickets_deployment! if params[:update_tickets_deployment]
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
  
  def update
    @release = @releases.find(params[:id])
    
    if @release.update_attributes(params[:release])
      redirect_to @release, notice: "Release was successfully updated."
    else
      render action: "edit"
    end
  end
  
  def destroy
    @release = @releases.find(params[:id])
    @release.destroy
    
    redirect_to releases_url
  end
  
private
  
  def get_project_and_environment
    @project = Project.find_by_slug!(params[:project_id])
    @environment = params[:environment]
    @environment = Houston.config.environments.first unless Houston.config.environments.member?(@environment)
    @releases = @project.releases.to_environment(@environment)
  end
  
end

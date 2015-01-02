class ReleasesController < ApplicationController
  include UrlHelper
  before_filter :get_project_and_environment
  before_filter :load_tickets, only: [:new, :edit, :create, :update]
  
  def index
    @title = "Releases • #{@project.name}"
    @title << " (#{@environment})" if @environment
  end
  
  def show
    @release = @releases.find(params[:id])
    authorize! :show, @release
    
    @title = "Release #{@release.release_date.strftime("%-m/%d")} • #{@project.name}"
  end
  
  def new
    @title = "New Release (#{@environment}) • #{@project.name}"
    
    @deploy = Deploy.find_by_id(params[:deploy_id])
    @commit0 = params.fetch :commit0, @releases.most_recent_commit
    @commit1 = params.fetch :commit1, @deploy.try(:commit)
    @release = @releases.new(commit0: @commit0, commit1: @commit1, deploy: @deploy)
    authorize! :create, @release
    
    @manual = params[:manual] == "true" || !@project.has_version_control?
    
    if @release.can_read_commits?
      @release.load_commits!
      @release.load_tickets!
      @release.build_changes_from_commits
    end
    
    @release.release_changes = [ReleaseChange.new(@release, "", "")] if @release.release_changes.none?
    
    if request.headers["X-PJAX"]
      render template: "releases/_new_release", layout: false
    else
      render
    end
  end

  def edit
    @release = @releases.find(params[:id])
    authorize! :update, @release
    
    if params[:recreate]
      if @release.can_read_commits?
        @release.load_commits!
        @release.load_tickets!
        @release.build_changes_from_commits
      end
    end
    
    @release.release_changes = [ReleaseChange.new(@release, "", "")] if @release.release_changes.none?
    @release.valid?
  end

  def create
    @release = @releases.new(params[:release])
    @release.user = current_user
    authorize! :create, @release
    
    if @release.save
      ProjectNotification.release(@release).deliver! if params[:send_release_email]
      @release.tickets.resolve_all! if params[:resolve_tickets]
      
      Houston.track_event current_user, "created-release",
        project: @release.project.slug,
        environment: @release.environment_name
      
      redirect_to @release
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
    authorize! :update, @release
    
    if @release.update_attributes(params[:release])
      redirect_to @release, notice: "Release was successfully updated."
    else
      render action: "edit"
    end
  end
  
  def destroy
    @release = @releases.find(params[:id])
    authorize! :destroy, @release
    
    @release.destroy
    
    redirect_to releases_url
  end
  
private
  
  def get_project_and_environment
    @project = Project.find_by_slug!(params[:project_id])
    @environment = params[:environment]
    @environment = Houston.config.environments.first unless Houston.config.environments.member?(@environment)
    @releases = @project.releases
      .to_environment(@environment)
      .includes(:project)
      .includes(:deploy)
  end
  
  def load_tickets
    @tickets = @project.tickets.includes(:project).map do |ticket|
      { id: ticket.id,
        summary: ticket.summary,
        closed: ticket.closed_at.present?,
        ticketUrl: ticket.ticket_tracker_ticket_url,
        number: ticket.number }
    end
  end
  
end

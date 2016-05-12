class ReleasesController < ApplicationController
  include UrlHelper
  include ReleaseHelper
  before_filter :get_release_and_project, only: [:show, :edit, :update, :destroy]
  before_filter :get_project_and_environment, only: [:index, :new, :create]
  before_filter :load_tickets, only: [:new, :edit, :create, :update]



  def index
    @title = "Releases • #{@project.name}"
    @title << " (#{@environment})" if @environment
    @q = params[:q]
    @q = nil if @q.blank?
    @releases = @project.releases.preload(:deploy).search(@q) if @q

    render partial: (@q ? "releases/results" : "releases/index") if request.xhr?
  end

  def new
    @title = "New Release (#{@environment}) • #{@project.name}"

    @deploy = Deploy.find_by_id(params[:deploy_id])
    @releases = @releases.before(@deploy.completed_at) if @deploy
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

  def create
    @release = @releases.new(params[:release])
    @release.user = current_user
    authorize! :create, @release

    if @release.save
      ProjectNotification.release(@release).deliver! if params[:send_release_email]
      @release.tickets.resolve_all! if params[:resolve_tickets]

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



  def show
    authorize! :show, @release

    @title = "Release #{@release.release_date.strftime("%b %-d")} • #{@project.name}"

    if request.format.oembed?
      render json: MultiJson.dump({
        version: "1.0",
        type: "rich",
        author_name: "#{@project.slug} / #{@release.environment_name}",
        title: format_release_subject(@release),
        html: format_release_description(@release) })
    end
  end

  def edit
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

  def update
    authorize! :update, @release

    if @release.update_attributes(params[:release])
      redirect_to @release, notice: "Release was successfully updated."
    else
      render action: "edit"
    end
  end

  def destroy
    authorize! :destroy, @release

    @release.destroy

    redirect_to releases_url
  end

private

  def get_release_and_project
    @release = Release.find(params[:id])
    @project = @release.project
  end

  def get_project_and_environment
    @project = Project.find_by_slug!(params[:project_id])
    @environment = params[:environment] || @project.environments_with_release_notes.first
    @deploys = @project.deploys
      .completed
      .to(@environment)
      .includes(:commit)
      .includes(:release)
    @releases = @project.releases
      .to(@environment)
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

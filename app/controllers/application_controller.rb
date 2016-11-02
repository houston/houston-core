class ApplicationController < ActionController::Base
  include UrlHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_current_project
  after_action :save_current_project


  delegate :mobile?, to: "browser.device"
  helper_method :mobile?, :unfurling?


  rescue_from CanCan::AccessDenied do |exception|
    if current_user
      if request.xhr?
        render plain: exception.message, status: :unauthorized
      else
        redirect_url = request.referrer.blank? ? main_app.root_url : :back
        redirect_to redirect_url, :alert => exception.message
      end
    else
      session["user.return_to"] = request.url
      require_login
    end
  end

  rescue_from UserCredentials::MissingCredentials do
    head 401, "X-Credentials" => "Missing Credentials"
  end

  rescue_from UserCredentials::InvalidCredentials do
    head 401, "X-Credentials" => "Invalid Credentials"
  end

  rescue_from UserCredentials::InsufficientPermissions do |exception|
    render plain: exception.message, status: 401
  end

  rescue_from Github::Unauthorized do |exception|
    session["user.return_to"] = request.referer
    if request.xhr?
      head 401, "X-Credentials" => "Oauth", "Location" => oauth_consumer_path(id: "github")
    else
      redirect_to oauth_consumer_path(id: "github")
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    render file: "public/404", layout: false
  end

  # Malformed request
  rescue_from ActionController::UnknownFormat do
    head 400
  end unless Rails.env.development?



  def require_login
    redirect_to main_app.new_user_session_path
  end



  def unfurling?
    request.env["HTTP_USER_AGENT"] =~ /^Slackbot-LinkExpanding/
  end



  def after_sign_in_path_for(user)
    path = session["user_redirect_to"] || stored_location_for(user) || root_path
    path = root_path if path =~ /\/users\/(sign_in|password)/
    path
  end



  def revision
    expire_revision!
    return_or_cache_revision!
  end

  def expire_revision!
    if session[:revision_expiration].blank? || session[:revision_expiration] < Time.now.utc
      session[:revision] = nil
      Rails.logger.info "[revision] expiring"
    end
  end

  def return_or_cache_revision!
    session[:revision] || read_revision.tap do |sha|
      session[:revision] = sha
      session[:revision_expiration] = 3.minutes.from_now
      Rails.logger.info "[revision] sha: #{sha[0..8]}, expiration: #{session[:revision_expiration]}"
    end
  end

  def read_revision
    revision_path = Rails.root.join("REVISION")
    File.exists?(revision_path) ? File.read(revision_path).chomp : ""
  end



  def api_authenticate!
    return if current_user

    allow_params_authentication!
    authenticate_or_request_with_http_basic do |username, password|
      params["user"] ||= {}
      params["user"].merge!(email: username, password: password)
      user = warden.authenticate(scope: :user)
      if user
        sign_in(:user, user)
      else
        head :unauthorized
      end
    end
  end



  helper_method :followed_projects
  def followed_projects
    return @followed_projects if defined?(@followed_projects)
    return @followed_projects = [] unless current_user
    @followed_projects = current_user.followed_projects.to_a
  end

  helper_method :current_project
  def current_project
    @current_project ||= @project || (@default_project_slug ? Project[@default_project_slug] : (current_user && current_user.current_project))
  end

  def set_current_project
    @default_project_slug = params[:project] if params[:project].is_a?(String)
  end

  def save_current_project
    return unless current_user && current_project

    current_user.current_project_id = current_project.id
    current_user.save if current_user.current_project_id_changed?
  end



  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end



end

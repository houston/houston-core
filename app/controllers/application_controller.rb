class ApplicationController < ActionController::Base
  include UrlHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :token_authenticate!
  around_action :with_current_project


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
      store_location_for(:user, request.url)
      require_login
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    render file: Houston.root.join("public/404"), layout: false
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
    path = session["user.redirect_to"] || stored_location_for(user) || root_path
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



  def token_authenticate!
    return if current_user

    token = request.authorization[/\ABearer (.*)\z/, 1] if request.authorization
    user = User.joins(:api_tokens).find_by(api_tokens: { value: token }) if token
    return unless user

    @current_user = user
    @authenticated_via_token = true
  end

  def authenticated_via_token?
    @authenticated_via_token == true
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

  def with_current_project
    @default_project_slug = params[:project] if params[:project].is_a?(String)

    yield

    if current_user && current_project
      current_user.current_project_id = current_project.id
      current_user.save if current_user.current_project_id_changed?
    end
  end



  def oauth_authorize!(klass, scope:, redirect_to: nil)
    authorization = klass.for(current_user).find_or_create_by!(scope: scope)
    raise ArgumentError, "authorization already exists" if authorization.granted?
    session["#{authorization.id}_granted_redirect_url"] = redirect_to if redirect_to
    redirect_to authorization.url
  end



  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end



end

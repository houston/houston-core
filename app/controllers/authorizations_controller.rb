class AuthorizationsController < ApplicationController

  def index
    @title = "Authorizations"
    authorize! :read, Authorization
    @authorizations = Authorization.all
  end

  def new
    @title = "New Authorization"
    authorize! :create, Authorization
    @authorization = Authorization.new
  end

  def create
    @authorization = Authorization.new(params[:authorization])
    authorize! :create, @authorization

    if @authorization.save
      redirect_to authorizations_path
    else
      render action: :new
    end
  end

  def edit
    @title = "Edit Authorization"
    @authorization = Authorization.find params[:id]
    authorize! :update, Authorization
  end

  def update
    @authorization = Authorization.find params[:id]
    authorize! :update, Authorization

    if @authorization.update_attributes(params[:authorization])
      redirect_to authorizations_path
    else
      render action: :new
    end
  end

  def grant
    @authorization = Authorization.find(params[:id])
    if @authorization.granted?
      redirect_to authorizations_url, notice: "Already Granted"
    else
      puts "\e[96;4m#{@authorization.authorize_url}\e[0m"
      redirect_to @authorization.authorize_url
    end
  end

  def oauth2_callback
    authorization = Authorization.set_access_token! params
    redirect_to authorization_granted_url(authorization)
  end

  def granted
  end

end

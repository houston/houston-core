class AuthorizationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @title = "Authorizations"
    authorize! :read, :all_authorizations
    @authorizations = Authorization.all.preload(:user)
  end

  def mine
    @title = "My Authorizations"
    authorize! :create, Authorization
    @authorizations = current_user.authorizations
    render action: :index
  end

  def new
    @title = "New Authorization"
    authorize! :create, Authorization
    @authorization = Authorization.new
  end

  def create
    @authorization = current_user.authorizations.build(params[:authorization])
    authorize! :create, @authorization

    if @authorization.save
      redirect_to my_authorizations_path
    else
      render action: :new, error: @authorization.errors.full_messages.to_sentence
    end
  end

  def edit
    @title = "Edit Authorization"
    @authorization = Authorization.find params[:id]
    authorize! :update, @authorization
  end

  def update
    @authorization = Authorization.find params[:id]
    authorize! :update, @authorization

    if @authorization.update_attributes(params[:authorization])
      redirect_to my_authorizations_path
    else
      render action: :new
    end
  end

  def destroy
    @authorization = Authorization.find params[:id]
    authorize! :destroy, @authorization

    @authorization.destroy
    redirect_to my_authorizations_path, notice: "Authorization to #{@authorization.provider_name} revoked"
  end

  def grant
    @authorization = Authorization.find(params[:id])
    if @authorization.granted?
      redirect_to authorizations_url, notice: "Already Granted"
    else
      redirect_to @authorization.authorize_url
    end
  end

  def oauth2_callback
    if params.key?(:code) && params.key?(:state)
      authorization = Authorization.set_access_token! params
      redirect_to authorization_granted_url(authorization)
    else
      @error = params.fetch(:error, "An unknown error occurred")
    end
  end

  def granted
  end

end

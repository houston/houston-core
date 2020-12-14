class UsersController < ApplicationController
  before_action :extract_role, :only => [:update, :create]
  load_and_authorize_resource


  def index
    @title = "Users"
    @users = User.unretired
  end


  def show
    @user = User.find(params[:id])
    @title = @user.name
  end


  def new
    @user = User.new
  end


  def edit
    @user = User.find(params[:id])
  end


  def invite
    @user = User.find(params[:id])
    @user.invite!
    redirect_to request.referrer, :notice => "#{@user.name} has been invited to use this program"
  end


  def create
    @user = User.new(user_params)

    if params[:send_invitation]
      User.invite!(params[:user])
    else
      @user.role = @role
      @user.save!
    end

    redirect_to @user, notice: 'User was successfully invited.'

  rescue ActiveRecord::RecordInvalid
    flash.now[:error] = @user.errors[:base].join("\n")
    render action: "new"
  end


  def update
    @user = User.find(params[:id])
    @user.role = @role

    attributes = user_params
    attributes[:alias_emails] = attributes.fetch(:alias_emails, "").split.map(&:strip)
    @user.props.merge! attributes.delete(:props) if attributes.key?(:props)

    if @user.update_attributes(attributes)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      flash.now[:error] = @user.errors[:base].join("\n")
      render action: "edit"
    end
  end


  def destroy
    @user = User.find(params[:id])
    @user.retire!

    redirect_to users_url
  end


private


  def extract_role
    @role = params[:user].delete(:role)
    if current_user.owner?
      @role = "Owner" if current_user.id == params[:id].to_i # Owners can't demote themselves
    else
      @role = "Member" # Others can't promote themselves
    end
  end


  def user_params
    params.permit(user: [
      :first_name,
      :last_name,
      :email,
      :password,
      :password_confirmation,
      :remember_me,
      :environments_subscribed_to,
      :view_options,
      :alias_emails,
      { props: {} }
    ])[:user]
  end


end

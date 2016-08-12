class UsersController < ApplicationController
  before_filter :extract_administrator, :only => [:update, :create]
  load_and_authorize_resource


  def index
    @title = "Users"
    @users = User.unretired
  end


  def show
    @user = User.find(params[:id])
    @title = @user.name
    @stats = stats_for_user(@user)
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
      @user.administrator = @administrator
      @user.save!
    end

    redirect_to @user, notice: 'User was successfully invited.'

  rescue ActiveRecord::RecordInvalid
    flash.now[:error] = @user.errors[:base].join("\n")
    render action: "new"
  end


  def update
    @user = User.find(params[:id])
    @user.administrator = @administrator

    attributes = params[:user]
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


  def extract_administrator
    @administrator = params[:user].delete(:administrator) == "1"
    @administrator = false unless current_user.administrator?
  end


  def stats_for_user(user)
    ticket_resolutions = user.tickets.pluck(:resolution)
    filed_tickets = ticket_resolutions.count
    invalid_tickets = ticket_resolutions.count { |resolution| %w{invalid duplicate}.member?(resolution) }
    fixed_tickets = ticket_resolutions.count { |resolution| resolution == "fixed" }
    percent = 100.0 / filed_tickets

    {
      tickets: filed_tickets,
      invalid_tickets: invalid_tickets * percent,
      fixed_tickets: fixed_tickets * percent
    }
  end


  def user_params
    params.require(:user).permit(:first_name, :last_name, :email,
                    :role, :password, :password_confirmation, :remember_me,
                    :environments_subscribed_to, :view_options, :alias_emails)
  end


end

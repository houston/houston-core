class UsersController < ApplicationController
  before_filter :extract_administrator, :only => [:update, :create]
  load_and_authorize_resource
  
  # GET /users
  # GET /users.json
  def index
    @title = "Users"
    
    @users = User.all
    
    severities_colors = Houston.config.severities
    
    tickets = UnfuddleDump.load!
    @last_updated = UnfuddleDump.last_updated
    
    @ticket_stats_by_user = {}
    @users.each do |user|
      next unless user.unfuddle_id
      
      tickets_for_user = tickets.select { |ticket| ticket["reporter_id"] == user.unfuddle_id }
      resolutions = %w{invalid duplicate}
      invalid_tickets = tickets_for_user.select { |ticket| resolutions.member?(ticket["resolution"]) }.length
      fixed_tickets = tickets_for_user.select { |ticket| ticket["resolution"] == "fixed" }.length
      percent = 100.0 / tickets_for_user.length
      
      tickets_by_severity = Hash[severities_colors.values.zip([0] * severities_colors.values.length)]
      tickets_for_user.each do |ticket|
        severity = ticket["severity"]
        severity = nil if severity.blank?
        color = severities_colors[severity]
        tickets_by_severity[color] += 1
      end
      
      @ticket_stats_by_user[user] = {
        tickets: tickets_for_user.length,
        invalid_tickets: invalid_tickets * percent,
        fixed_tickets: fixed_tickets * percent,
        tickets_by_severity: tickets_by_severity
      }
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    @title = @user.name
    
    if @user.unfuddle_id
      
      url = "ticket_reports/dynamic.json"
      url << "?conditions_string=reporter-eq-#{@user.unfuddle_id}"
      url << "&fields_string=#{%w{project number summary resolution}.join("|")}"
      url << "&pretty=true&exclude_description=true"
      response = Unfuddle.get(url)
      
      binding.pry unless response.status == 200
      report = response.json
      group0 = report.fetch("groups", [])[0] || {}
      tickets_for_user = group0.fetch("tickets", [])
      
      resolutions = %w{invalid duplicate}
      invalid_tickets = tickets_for_user.select { |ticket| resolutions.member?(ticket["resolution"]) }.length
      fixed_tickets = tickets_for_user.select { |ticket| ticket["resolution"] == "fixed" }.length
      percent = 100.0 / tickets_for_user.length
      
      @stats = {
        tickets: tickets_for_user.length,
        invalid_tickets: invalid_tickets * percent,
        fixed_tickets: fixed_tickets * percent }
      
    else
      
      @stats = {
        tickets: 0,
        invalid_tickets: 1/0.0, # NaN
        fixed_tickets: 1/0.0 } # NaN
      
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  def invite
    @user = User.find(params[:id])
    @user.invite!
    redirect_to request.referrer, :notice => "#{@user.name} has been invited to use this program"
  end

  # POST /users
  # POST /users.json
  def create
    if params[:send_invitation]
      @user = User.invite!(params[:user])
    else
      notifications_pairs = params[:user].delete(:notifications_pairs)
      @user = User.new(params[:user])
      @user.skip_password = true
      @user.save!
      @user.notifications_pairs = notifications_pairs if notifications_pairs
    end
    
    @user.administrator = @administrator
    
    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully invited.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])
    @user.administrator = @administrator

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
  
  
private
  
  
  def extract_administrator
    @administrator = params[:user].delete(:administrator) == "1"
    @administrator = false unless current_user.administrator?
  end
  
  
end

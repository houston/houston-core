class UsersController < ApplicationController
  before_filter :extract_administrator, :only => [:update, :create]
  load_and_authorize_resource
  
  
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
  end
  
  
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
    
    if @user.save
      redirect_to @user, notice: 'User was successfully invited.'
    else
      render action: "new"
    end
  end
  
  
  def update
    @user = User.find(params[:id])
    @user.administrator = @administrator
    
    if @user.update_attributes(params[:user])
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render action: "edit"
    end
  end
  
  
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    
    redirect_to users_url
  end
  
  
private
  
  
  def extract_administrator
    @administrator = params[:user].delete(:administrator) == "1"
    @administrator = false unless current_user.administrator?
  end
  
  
end

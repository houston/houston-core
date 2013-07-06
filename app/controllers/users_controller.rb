class UsersController < ApplicationController
  before_filter :extract_administrator, :only => [:update, :create]
  load_and_authorize_resource
  
  
  def index
    @title = "Team"
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
        tickets_by_severity[color] += 1 if tickets_by_severity.key?(color)
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
    @stats = {
      tickets: 0,
      invalid_tickets: 1/0.0, # NaN
      fixed_tickets: 1/0.0 } # NaN
    
    if @user.unfuddle_id
      begin
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
      
      rescue Unfuddle::ConnectionError
      end
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
    @user = User.new(params[:user])
    
    if params[:send_invitation]
      User.invite!(params[:user])
    else
      @user.administrator = @administrator
      @user.skip_password = true
      @user.save!
    end
    
    redirect_to @user, notice: 'User was successfully invited.'
    
  rescue ActiveRecord::RecordInvalid
    render action: "new"
  end
  
  
  def update
    @user = User.find(params[:id])
    @user.administrator = @administrator
    
    attributes = params[:user]
    attributes[:environments_subscribed_to] = params[:send_release_notes].select { |_, value| value == "1" }.keys
    
    if @user.update_attributes(attributes)
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

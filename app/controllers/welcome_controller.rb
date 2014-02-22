class WelcomeController < ApplicationController
  before_filter :authenticate_user!
  layout "minimal"
  
  def index
    if params[:since]
      time = Time.parse(params[:since])
      @last_date = time.to_date
    else
      time = Time.now
      @last_date = nil
    end
    
    @events = ActivityFeed.new(followed_projects, time, count: 150).events
    @project_tdls = ProjectTDL.for(followed_projects, current_user)
    
    if request.xhr?
      render partial: "activity/events"
    end
  end
  
end
  
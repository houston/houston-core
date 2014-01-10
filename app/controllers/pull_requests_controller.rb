class PullRequestsController < ApplicationController
  before_filter :authenticate_user!
  
  rescue_from Github::Unauthorized do |exception|
    redirect_to oauth_consumer_path(id: "github")
  end
  
  def index
    @pull_requests_by_repo = Github::PullRequests.new(current_user).to_h
  end
  
end

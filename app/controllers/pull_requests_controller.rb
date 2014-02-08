class PullRequestsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    @title = "Pull Requests"
    @pull_requests_by_repo = Github::PullRequests.new(current_user).to_h
  end
  
end

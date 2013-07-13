class SelfCommitsController < ApplicationController
  before_filter :api_authenticate!
  
  def index
    commits = current_user.commits
    
    start_at = params[:start_at].to_time if params[:start_at]
    end_at = params[:end_at].to_time if params[:end_at]
    commits = commits.during(start_at..end_at) if start_at && end_at
    
    render json: CommitPresenter.new(commits)
  end
  
end

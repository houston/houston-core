class CommitsController < ApplicationController
  before_filter :api_authenticate!
   
  def index
    commits = Commit.includes(:releases).includes(:committers).includes(:project)
    
    start_at = params[:start_at].to_time if params[:start_at]
    end_at = params[:end_at].to_time if params[:end_at]
    end_at ||= Time.now if start_at
    commits = commits.during(start_at..end_at) if start_at && end_at
    
    render json: CommitPresenter.new(commits).verbose
  end
  
  def self
    commits = current_user.commits.includes(:releases).includes(:committers).includes(:project)
    
    start_at = params[:start_at].to_time if params[:start_at]
    end_at = params[:end_at].to_time if params[:end_at]
    end_at ||= Time.now if start_at
    commits = commits.during(start_at..end_at) if start_at && end_at
    
    render json: CommitPresenter.new(commits).verbose
  end
  
end

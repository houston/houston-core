class Github::PullsController < ApplicationController

  def index
    @pulls = Github::PullRequest.order(created_at: :desc)
    @title = "Pull Requests (#{@pulls.count})"
  end

end

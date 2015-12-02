class Github::PullsController < ApplicationController

  def index
    @pulls = Github::PullRequest.all
    @title = "Pull Requests (#{@pulls.count})"
  end

end

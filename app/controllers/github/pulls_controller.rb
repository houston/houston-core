class Github::PullsController < ApplicationController

  def index
    @pulls = Github::PullRequest.order(created_at: :desc).preload(:project, :user)
    @labels = @pulls.flat_map(&:labels).uniq { |label| label["name"] }.sort_by { |label| label["name"] }
    @selected_labels = params.fetch(:only, "").split(/,\s*/)
    @selected_labels = @labels.map { |label| label["name"] } if @selected_labels.none?
    @selected_labels -= params.fetch(:except, "").split(/,\s*/)
    @title = "Pull Requests (#{@pulls.count})"
  end

end

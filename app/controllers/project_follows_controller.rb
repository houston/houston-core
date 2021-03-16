class ProjectFollowsController < ApplicationController
  attr_reader :project
  before_action :find_project


  def create
    current_user.follow! project
    redirect_back fallback_location: root_path, notice: "You are now following #{project.name}"
  end

  def destroy
    current_user.unfollow! project
    redirect_back fallback_location: root_path, notice: "You are no longer following #{project.name}"
  end


private

  def find_project
    @project = Project.find_by_slug!(params[:project_id])
  end

end

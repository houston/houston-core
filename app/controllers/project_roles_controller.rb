class ProjectRolesController < ApplicationController
  before_action :find_project


  def create
    Role.where(project_id: @project.id, user_id: current_user.id).first_or_create(name: "Follower")
    redirect_to :back, notice: "You are now following #{@project.name}"
  end

  def destroy
    Role.where(project_id: @project.id, user_id: current_user.id).delete_all
    redirect_to :back, notice: "You are no longer following #{@project.name}"
  end


private

  def find_project
    @project = Project.find_by_slug!(params[:project_id])
  end

end

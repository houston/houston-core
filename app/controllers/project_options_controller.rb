class ProjectOptionsController < ApplicationController
  before_filter :get_project
  attr_reader :project


  def update
    project.props.merge! params[:options]
    project.save!
    head :ok
  end


  def destroy
    project.props.delete! params[:key]
    project.save!
    head :ok
  end


private

  def get_project
    @project = Project.find_by_slug!(params[:slug])
    authorize! :read, @project
  end

end

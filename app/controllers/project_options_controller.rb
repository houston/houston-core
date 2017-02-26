class ProjectOptionsController < ApplicationController
  before_action :get_project
  attr_reader :project


  def update
    project.props.merge! params[:options].to_unsafe_hash # <-- TODO: should props be declared and then permitted?
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

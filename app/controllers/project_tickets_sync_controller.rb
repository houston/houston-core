class ProjectTicketsSyncController < ApplicationController
  before_action :find_project


  def show
    render json: @project.ticket_tracker_sync_in_progress?, status: :ok
  end


  def create
    SyncProjectTicketsJob.new(@project).run!
    head :ok
  end


private

  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end

end

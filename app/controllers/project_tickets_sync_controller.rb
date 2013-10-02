class ProjectTicketsSyncController < ApplicationController
  before_filter :find_project
  
  
  def show
    render json: @project.ticket_tracker_sync_in_progress?, status: :ok
  end
  
  
  def create
    benchmark "\e[33m[sync] sync tickets for \e[1m#{@project.slug}\e[0;33m" do
      SyncProjectTicketsJob.new(@project).run!
    end
    head :ok
  end
  
  
private
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
end

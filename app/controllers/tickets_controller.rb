class TicketsController < ApplicationController
  
  def index
    @tickets = UnfuddleDump.load!
    @last_updated = UnfuddleDump.last_updated
    
    users = Unfuddle.instance.get("people.json?removed=true").json
    @user_names_by_ids = {}
    users.each do |user|
      @user_names_by_ids[user["id"]] = "#{user["first_name"].strip} #{user["last_name"].strip}"
    end
    
    projects = Unfuddle.instance.get("projects.json?removed=true").json
    @project_names_by_ids = {}
    projects.each do |project|
      @project_names_by_ids[project["id"]] = project["title"]
    end
  end
  
  def show
    ticket = Ticket.find(params[:id])
    render :json => TicketPresenter.new(ticket).with_testing_notes
  end
  
  def update
    ticket = Ticket.find(params[:id])
    params[:last_release_at] = params.fetch(:lastReleaseAt, params[:last_release_at])
    attributes = params.pick(:last_release_at, :priority)
    
    if ticket.update_attributes(attributes)
      render json: []
    else
      render json: ticket.errors, status: :unprocessable_entity
    end
  end
  
  def close
    ticket = Ticket.find(params[:id])
    ticket.close_ticket!
    render json: [], :status => :ok
  rescue
    render json: [$!.message], :status => :unprocessable_entity
  end
  
  def reopen
    ticket = Ticket.find(params[:id])
    ticket.reopen!
    render json: [], :status => :ok
  rescue
    render json: [$!.message], :status => :unprocessable_entity
  end
  
end

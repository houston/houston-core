class TicketsController < ApplicationController
  
  def index
    @tickets = UnfuddleDump.load!
    @last_updated = UnfuddleDump.last_updated
    
    users = Unfuddle.instance.get("people.json?removed=true")[1]
    @user_names_by_ids = {}
    users.each do |user|
      @user_names_by_ids[user["id"]] = "#{user["first_name"].strip} #{user["last_name"].strip}"
    end
    
    projects = Unfuddle.instance.get("projects.json?removed=true")[1]
    @project_names_by_ids = {}
    projects.each do |project|
      @project_names_by_ids[project["id"]] = project["title"]
    end
  end
  
  def update
    ticket = Ticket.find(params[:id])
    if ticket.update_attributes(last_release_at: params[:lastReleaseAt])
      render json: [], :status => :ok
    else
      render json: ticket.errors, :status => :unprocessable_entity
    end
  end
  
  def close
    ticket = Ticket.find(params[:id])
    ticket.close_ticket!
    render json: [], :status => :ok
  rescue
    render json: [$!.message], :status => :unprocessable_entity
  end
  
end

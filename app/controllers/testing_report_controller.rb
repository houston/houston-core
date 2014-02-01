class TestingReportController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_project, only: [:show]
  
  
  def index
    @title = "Testing Report"
    
    @projects = followed_projects.select { |project| can?(:read, project.testing_notes.build) }
    @tickets = Ticket.for_projects @projects
  end
  
  
  def show
    @title = "Testing Report: #{@project.name}"
    authorize! :show, @project.testing_notes.build
    
    @projects = [@project]
    @tickets = @project.tickets
  end
  
  
private
  
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
  
  def default_render
    @tickets = tickets_for_testing_report(@tickets)
    @tickets = TicketPresenter.new(@tickets).with_testing_notes
    render json: @tickets if request.xhr?
    super
  end
  
  
  def tickets_for_testing_report(tickets)
    tickets
      .unclosed
      .fixed
      .deployed
      .includes(:project)
      .includes(:testing_notes)
      .includes(:releases)
      .includes(:commits)
      .order("projects.name ASC")
  end
  
  
end

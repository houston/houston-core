class TestingReportController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_project, only: [:show]
  
  
  def index
    @title = "Testing Report"
    
    @projects = followed_projects.select { |project| can?(:read, project.testing_notes.build) }
    @tickets = Ticket.for_projects @projects
  end
  
  
  def show
    @title = "Testing Report • #{@project.name}"
    authorize! :show, @project.testing_notes.build
    
    @projects = [@project]
    @tickets = @project.tickets
  end
  
  
private
  
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
  
  def default_render
    @tickets = TestingReportTicketPresenter.new(@tickets).as_json
    render json: @tickts if request.xhr?
    super
  end
  
  
end

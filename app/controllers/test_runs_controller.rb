class TestRunsController < ApplicationController
  
  def show
    @project = Project.find_by_slug!(params[:slug])
    @test_run = @project.test_runs.find_by_commit(params[:commit]) || (raise ActiveRecord::RecordNotFound)
    render template: "project_notification/test_run", layout: "email"
  end
  
end

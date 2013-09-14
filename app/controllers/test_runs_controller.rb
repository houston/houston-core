class TestRunsController < ApplicationController
  before_filter :find_test_run
  
  def show
    render template: "project_notification/test_run", layout: "email"
  end
  
  def retry
    @test_run.retry!
    last_build_url = @project.ci_server.last_build_url if @project.ci_server.respond_to? :last_build_url
    redirect_to last_build_url || root_url, notice: "Build for #{@project.name} retried"
  end
  
private
  
  def find_test_run
    @project = Project.find_by_slug!(params[:slug])
    @test_run = @project.test_runs.find_by_sha(params[:commit]) || (raise ActiveRecord::RecordNotFound)
  end
  
end

class TestRunsController < ApplicationController
  before_filter :find_test_run
  skip_before_filter :verify_authenticity_token, only: [:save_results]

  def show
    @title = "Test Results for #{@test_run.sha[0...8]}"
    render template: "project_notification/test_run"
  end

  def confirm_retry
  end

  def retry
    @test_run.retry!

    build_url = if @project.ci_server.respond_to? :last_build_progress_url
      @project.ci_server.last_build_progress_url
    elsif @project.ci_server.respond_to? :last_build_url
      @project.ci_server.last_build_url
    end

    if build_url
      redirect_to build_url
    else
      redirect_to root_url, notice: "Build for #{@project.name} retried"
    end
  end

  def save_results
    results_url = params[:results_url]

    if results_url.blank?
      message = "#{@project.ci_server_name} is not appropriately configured to build #{@project.name}."
      additional_info = "#{@project.ci_server_name} did not supply 'results_url' when it triggered the post_build hook"
      ProjectNotification.ci_configuration_error(@test_run, message, additional_info: additional_info).deliver!
      return
    end

    @test_run.completed!(results_url)
    head :ok
  end

private

  def find_test_run
    @project = Project.find_by_slug!(params[:slug])
    @test_run = @project.test_runs.find_by_sha!(params[:commit])
  end

end

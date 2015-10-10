class JobsController < ApplicationController

  def show
    authorize! :show, :jobs
  end

  def run
    authorize! :run, :jobs
    Houston.jobs.run_async params[:slug]
    redirect_to "/jobs", notice: "#{params[:slug]} is running"
  end

end

class JobsController < ApplicationController
  
  def show
    authorize! :show, :jobs
  end
  
end

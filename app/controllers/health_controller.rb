class HealthController < ApplicationController
  
  def show
    authorize! :show, :health
  end
  
end

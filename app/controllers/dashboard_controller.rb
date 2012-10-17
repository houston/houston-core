class DashboardController < ApplicationController
  before_filter :set_fnord_options
  
  def index
  end
  
private
  
  def set_fnord_options
    @host = "localhost:4242"
    @namespace = "changelog"
  end
  
end

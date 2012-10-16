class FnordController < ApplicationController
  before_filter :set_fnord_options
  
  def index
  end
  
  def dashboard
    response = Faraday.get("http://#{@host}/#{params[:namespace]}/dashboard/#{params[:dashboard]}")
    render content_type: "text/json", text: response.body
  end
  
private
  
  def set_fnord_options
    @host = "localhost:4242"
    @namespace = "changelog"
  end
  
end

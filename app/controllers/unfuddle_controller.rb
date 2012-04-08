class UnfuddleController < ApplicationController
  
  def render_from_unfuddle(path, params=nil)
    path = "#{path}.json"
    path << "?#{params}" if params
    response = unfuddle.get(path)
    render :json => response.body
  end
  
end

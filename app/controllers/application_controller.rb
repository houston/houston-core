class ApplicationController < ActionController::Base
  include FreightTrain
  protect_from_forgery
  
  def unfuddle
    @unfuddle ||= Unfuddle.new
  end
  
end

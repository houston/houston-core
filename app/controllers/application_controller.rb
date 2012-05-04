class ApplicationController < ActionController::Base
  include FreightTrain
  protect_from_forgery
  
  def unfuddle
    @unfuddle ||= Unfuddle.new
  end
  
  def after_sign_in_path_for(user)
    case user.role
    when "Tester"; user_path(user)
    else; root_path
    end
  end
  
end

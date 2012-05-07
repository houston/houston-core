class ApplicationController < ActionController::Base
  include FreightTrain
  protect_from_forgery
  
  rescue_from CanCan::AccessDenied do |exception|
    if current_user
      redirect_url = request.referrer.blank? ? root_url : :back
      redirect_to redirect_url, :alert => exception.message
    else
      require_login
    end
  end
  
  def require_login
    redirect_to new_user_session_path
  end
  
  
  
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

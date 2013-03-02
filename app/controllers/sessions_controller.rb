class SessionsController < Devise::SessionsController
  before_filter :store_location, :only => [:new]
  
  def store_location
    session["user_redirect_to"] = request.referer unless request.referer =~ /\/users\/sign_in/
  end
  
end

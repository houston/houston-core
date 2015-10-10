class TesterBarController < ApplicationController

  def login_as
    user = User.find_by_email(params[:email])
    if user
      flash[:notice] = "You have signed in as #{user.name}"
      sign_in(user)
    end
    redirect_to request.referrer || root_url
  end

end

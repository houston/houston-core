class UserOptionsController < ApplicationController
  before_filter :authenticate_user!


  def update
    current_user.view_options = current_user.view_options.merge(params[:options])
    current_user.save!
    head :ok
  end


  def destroy
    current_user.view_options = current_user.view_options.except(params[:key])
    current_user.save!
    head :ok
  end


end

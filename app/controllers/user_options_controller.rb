class UserOptionsController < ApplicationController
  before_filter :authenticate_user!


  def update
    current_user.props.merge! params[:options]
    current_user.save!
    head :ok
  end


  def destroy
    current_user.props.delete! params[:key]
    current_user.save!
    head :ok
  end


end

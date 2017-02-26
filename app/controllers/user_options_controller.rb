class UserOptionsController < ApplicationController
  before_action :authenticate_user!


  def update
    current_user.props.merge! params[:options].to_unsafe_hash # <-- TODO: should props be declared and then permitted?
    current_user.save!
    head :ok
  end


  def destroy
    current_user.props.delete! params[:key]
    current_user.save!
    head :ok
  end


end

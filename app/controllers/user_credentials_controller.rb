class UserCredentialsController < ApplicationController
  
  def upsert
    credentials = current_user.credentials.where(service: params[:service]).first_or_initialize
    credentials.login = params[:login]
    credentials.password = params[:password]
    
    if credentials.save
      head :ok
    else
      render json: credentials.errors, status: :unprocessable_entity
    end
  end
  
  def destroy
    credentials = current_user.credentials.find_by_id(params[:id])
    if credentials && credentials.delete
      redirect_to :back, notice: "Houston has deleted your credentials for #{credentials.service}"
    else
      redirect_to :back
    end
  end
  
end

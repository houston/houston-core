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
  
end

class UserCredentialsController < ApplicationController
  
  def upsert
    credentials = current_user.credentials.where(service: params[:service]).first_or_initialize
    credentials.login = params[:login]
    credentials.password = params[:password]
    credentials.save
    head :ok
  end
  
end

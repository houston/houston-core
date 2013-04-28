class SettingsController < ApplicationController
  load_and_authorize_resource
  
  def show
    @settings = Settings.new
  end
  
  def update
    @settings = Settings.new(params[:settings])
    @settings.save!
    redirect_to settings_path, :notice => "Changes saved"
  end
  
end

class DemoController < ApplicationController
  
  def index
    @colors = Rails.application.config.colors
    @ages = %w{young adult old}
  end
  
end

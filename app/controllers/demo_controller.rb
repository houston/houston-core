class DemoController < ApplicationController
  
  def index
    @colors = Houston.config.project_colors
    @ages = %w{young adult old}
  end
  
end

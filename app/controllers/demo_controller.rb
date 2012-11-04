class DemoController < ApplicationController
  
  def index
    @colors = Houston.config.colors
    @ages = %w{young adult old}
  end
  
end

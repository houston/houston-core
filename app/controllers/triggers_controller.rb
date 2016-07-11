class TriggersController < ApplicationController

  def index
    authorize! :show, :triggers
    @triggers = Houston.triggers
  end

end

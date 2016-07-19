class TriggersController < ApplicationController

  def index
    authorize! :read, Action
    @triggers = Houston.triggers
  end

end

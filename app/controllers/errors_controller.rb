class ErrorsController < ApplicationController

  def index
    authorize! :read, Action
    @actions = Action.where.not(error_id: nil).preload(:error).limit(50)
    @actions = @actions.where(Action.arel_table[:created_at].lt(params[:before])) if params[:before]
    render partial: "actions/actions" if request.xhr?
  end

end

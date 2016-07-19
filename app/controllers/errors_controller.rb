class ErrorsController < ApplicationController

  def index
    authorize! :read, Action
    @actions = Action.reorder(finished_at: :desc).where.not(error_id: nil).includes(:error).limit(50)
    @actions = @actions.where(Action.arel_table[:finished_at].lt(params[:before])) if params[:before]
    render partial: "errors/actions" if request.xhr?
  end

end

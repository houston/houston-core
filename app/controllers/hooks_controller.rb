class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def trigger
    event = "hooks:#{params[:hook]}"
    unless Houston.observer.observed?(event)
      render plain: "A hook with the slug '#{params[:hook]}' is not defined", status: 404
      return
    end

    payload = params.permit!.to_h.except(:action, :controller).merge({
      sender: {
        ip: request.remote_ip,
        agent: request.user_agent
      }
    })

    Houston.observer.fire event, params: payload
    head 200
  end

end

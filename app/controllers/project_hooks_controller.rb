class ProjectHooksController < ApplicationController
  skip_before_action :verify_authenticity_token


  def trigger
    project = Project.find_by_slug(params[:project_id])
    unless project
      render plain: "A project with the slug '#{params[:project_id]}' could not be found", status: 404
      return
    end

    event = "hooks:project:#{params[:hook]}"
    unless Houston.observer.observed?(event)
      render plain: "A hook with the slug '#{params[:hook]}' is not defined", status: 404
      return
    end

    payload = params.except(:action, :controller).merge({
      sender: {
        ip: request.remote_ip,
        agent: request.user_agent
      }
    })

    Houston.observer.fire event, project: project, params: payload
    head 200
  end


end

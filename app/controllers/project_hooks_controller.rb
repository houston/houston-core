class ProjectHooksController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  
  def trigger
    @project = Project.find_by_slug(params[:project_id])
    unless @project
      render text: "A project with the slug '#{params[:project_id]}' could not be found", status: 404
      return
    end
    
    Houston.observer.fire "hooks:#{params[:hook]}", params.dup
    
    head 200
  end
  
  
end

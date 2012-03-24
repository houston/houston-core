module UrlHelper
  
  def environments_path(*args)
    project_environments_path(*args)
  end
  
  def environment_path(environment, options={})
    project_environment_path(environment.project.to_param, environment, options)
  end
  
  def edit_environment_path(environment, options={})
    edit_project_environment_path(environment.project.to_param, environment, options)
  end
  
  
  def environments_url(*args)
    project_environments_url(*args)
  end
  
  def environment_url(environment, options={})
    project_environment_url(environment.project.to_param, environment, options)
  end
  
  def edit_environment_url(environment, options={})
    edit_project_environment_url(environment.project.to_param, environment, options)
  end
  
end

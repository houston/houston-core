module ProjectHelper
  
  def with_most_recent_release(project, environment_name)
    release = @releases[[project.id, environment_name]]
    if release
      release.project = project # so that _Release_ doesn't load project again
      yield release
    end
  end
  
end

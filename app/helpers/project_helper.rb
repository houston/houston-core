module ProjectHelper
  
  def with_most_recent_release(project, environment_name)
    release = @releases[[project.id, environment_name]]
    if release
      release.project = project.model # so that _Release_ doesn't load project again
      yield release
    end
  end
  
  def with_most_recent_test_run(project)
    test_run = @test_runs[project.id]
    if test_run
      test_run.project = project.model # so that _TestRun_ doesn't load project again
      yield test_run
    end
  end
  
end

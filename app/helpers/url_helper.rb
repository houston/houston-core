module UrlHelper
  
  
  
  def goldmine_case_number_url(number)
    "http://goldmineweb/DisplayCase.aspx?CaseNumber=#{number}"
  end
  
  
  
  def github_url?(project)
    project.repo.respond_to?(:project_url)
  end
  
  def github_project_url(project)
    project.repo.project_url if project.repo.respond_to?(:project_url)
  end
  
  def github_commit_url(project, sha)
    project.repo.commit_url(sha) if project.repo.respond_to?(:commit_url)
  end
  
  def github_commit_range_url(project, sha0, sha1)
    project.repo.commit_range_url(sha0, sha1) if project.repo.respond_to?(:commit_range_url)
  end
  
  
  
  def feature_path(project, feature)
    feature = Houston.config.get_project_feature feature
    feature.project_path project
  end
  
  def link_to_project_feature(project, feature)
    feature = Houston.config.get_project_feature feature
    link_to feature.name, feature.project_path(project)
  end
  
  
  
  def releases_path(project, *args)
    options = args.extract_options!
    environment_name = args.first
    if environment_name
      "/projects/#{project.to_param}/environments/#{environment_name}/releases"
    else
      super(project, options)
    end
  end
  
  def release_path(release, options={})
    super(release.project.to_param, release.environment_name, release, options)
  end
  
  def edit_release_path(release, options={})
    super(release.project.to_param, release.environment_name, release, options)
  end
  
  
  
  def release_url(release, options={})
    super(release.project.to_param, release.environment_name, release, options)
  end
  
  def edit_release_url(release, options={})
    super(release.project.to_param, release.environment_name, release, options)
  end
  
  def new_release_url(release, options={})
    super(release.project.to_param, release.environment_name, options.merge(deploy_id: release.deploy_id))
  end
  
  
  
end

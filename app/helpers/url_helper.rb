module UrlHelper

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
    feature = Houston.get_project_feature feature
    feature.project_path project
  end

  def link_to_project_feature(project, feature)
    feature = Houston.get_project_feature feature
    link_to feature.name, feature.project_path(project)
  end

end

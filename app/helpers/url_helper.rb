module UrlHelper

  def feature_path(project, feature)
    feature = Houston.get_project_feature feature
    feature.project_path project
  end

  def link_to_project_feature(project, feature)
    feature = Houston.get_project_feature feature
    link_to feature.name, feature.project_path(project)
  end

end

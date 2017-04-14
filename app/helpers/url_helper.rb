module UrlHelper

  def feature_path(project, feature)
    feature = Houston.project_features[feature]
    feature.path project
  end

  def link_to_project_feature(project, feature)
    feature = Houston.project_features[feature]
    link_to feature.name, feature.path(project)
  end

end

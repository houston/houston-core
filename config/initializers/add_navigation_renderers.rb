Houston.add_project_feature :settings do
  name "Settings"
  path { |project| Houston::Application.routes.url_helpers.edit_project_path(project) }
  ability { |ability, project| ability.can?(:update, project) }
end

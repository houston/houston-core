Houston.add_project_feature :ideas do
  name "Ideas"
  path { |project| Houston::Application.routes.url_helpers.project_open_ideas_path(project) }
  ability { |ability, project| ability.can?(:read, project.tickets.build) }
end

Houston.add_project_feature :bugs do
  name "Bugs"
  path { |project| Houston::Application.routes.url_helpers.project_open_bugs_path(project) }
  ability { |ability, project| ability.can?(:read, project.tickets.build) }
end

Houston.add_project_feature :settings do
  name "Settings"
  path { |project| Houston::Application.routes.url_helpers.edit_project_path(project) }
  ability { |ability, project| ability.can?(:update, project) }
end

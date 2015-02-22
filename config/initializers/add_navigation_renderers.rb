Houston.config.add_navigation_renderer :sprint do
  if can?(:read, Sprint)
    render_nav_link "Sprint", main_app.current_sprint_path, icon: "fa-burndown"
  end
end



Houston.config.add_project_feature :ideas do
  name "Ideas"
  icon "fa-lightbulb-o"
  path { |project| Houston::Application.routes.url_helpers.project_open_ideas_path(project) }
  ability { |ability, project| ability.can?(:read, project.tickets.build) }
end

Houston.config.add_project_feature :bugs do
  name "Bugs"
  icon "fa-bug"
  path { |project| Houston::Application.routes.url_helpers.project_open_bugs_path(project) }
  ability { |ability, project| ability.can?(:read, project.tickets.build) }
end

Houston.config.add_project_feature :testing do
  name "Testing"
  icon "fa-comments"
  path { |project| Houston::Application.routes.url_helpers.project_testing_report_path(project) }
end

Houston.config.add_project_feature :releases do
  name "Releases"
  icon "fa-paper-plane"
  path { |project| Houston::Application.routes.url_helpers.releases_path(project) }
  ability { |ability, project| ability.can?(:read, project.releases.build) }
end

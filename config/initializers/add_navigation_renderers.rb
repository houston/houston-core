Houston.config.add_navigation_renderer :pretickets do
  projects = followed_projects.select { |project| can?(:read, project.releases.build) }
  render_nav_menu "Pretickets", projects.map { |project| ProjectMenuItem.new(project, main_app.project_pretickets_path(project)) }
end

Houston.config.add_navigation_renderer :bugs do
  projects = followed_projects.select { |project| can?(:read, project.tickets.build) }
  render_nav_menu "Bugs", icon: "fa-bug", items: projects.map { |project| ProjectMenuItem.new(project, main_app.project_open_bugs_path(project)) }
end

Houston.config.add_navigation_renderer :ideas do
  projects = followed_projects.select { |project| can?(:read, project.tickets.build) }
  render_nav_menu "Ideas", icon: "fa-lightbulb-o", items: projects.map { |project| ProjectMenuItem.new(project, main_app.project_open_ideas_path(project)) }
end

Houston.config.add_navigation_renderer :sprint do
  if can?(:read, Sprint)
    render_nav_link "Sprint", main_app.current_sprint_path, icon: "fa-burndown"
  end
end

Houston.config.add_navigation_renderer :testing do
  projects = followed_projects.select { |project| can?(:read, project.tickets.build) }
  render_nav_menu "Testing", icon: "fa-comments", items: [
    MenuItem.new("All Projects", main_app.testing_report_path),
    MenuItemDivider.new ] +
    projects.map { |project| ProjectMenuItem.new(project, main_app.project_testing_report_path(project)) } if projects.any?
end

Houston.config.add_navigation_renderer :releases do
  projects = followed_projects.select { |project| can?(:read, project.releases.build) }
  render_nav_menu "Releases", icon: "fa-paper-plane", items: projects.map { |project| ProjectMenuItem.new(project, main_app.releases_path(project)) }
end

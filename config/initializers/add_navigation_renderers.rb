Houston.add_navigation_renderer :pulls do
  name "Pulls"
  path { Houston::Application.routes.url_helpers.pulls_path }
  ability { |ability| ability.can?(:read, Github::PullRequest) }
end



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

Houston.add_project_feature :releases do
  name "Releases"
  path { |project| Houston::Application.routes.url_helpers.releases_path(project) }
  ability { |ability, project| ability.can?(:read, project.releases.build) }

  field "releases.environments" do
    name "Environments"
    html do |f|
      if @project.environments.none?
        ""
      else
        html = <<-HTML
        <p class="instructions">
          Generate release notes for these environments:
        </p>
        HTML
        @project.environments.each do |environment|
          id = :"releases.ignore.#{environment}"
          value = f.object.public_send(id) || "0"
          html << f.label(id, class: "checkbox") do
            f.check_box(id, {checked: value == "0"}, "0", "1") +
            " #{environment.titleize}"
          end
        end
        html
      end
    end
  end

end

Houston.add_project_feature :settings do
  name "Settings"
  path { |project| Houston::Application.routes.url_helpers.edit_project_path(project) }
  ability { |ability, project| ability.can?(:update, project) }
end

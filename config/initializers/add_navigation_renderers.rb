Houston.add_navigation_renderer :sprint do
  if can?(:read, Sprint)
    render_nav_link "Sprint", main_app.current_sprint_path, icon: "fa-burndown"
  end
end

Houston.add_navigation_renderer :pulls do
  if can?(:read, Github::PullRequest)
    render_nav_link "Pulls", main_app.pulls_path, icon: "octokit-pull-request"
  end
end



Houston.add_project_feature :ideas do
  name "Ideas"
  icon "fa-lightbulb-o"
  path { |project| Houston::Application.routes.url_helpers.project_open_ideas_path(project) }
  ability { |ability, project| ability.can?(:read, project.tickets.build) }
end

Houston.add_project_feature :bugs do
  name "Bugs"
  icon "fa-bug"
  path { |project| Houston::Application.routes.url_helpers.project_open_bugs_path(project) }
  ability { |ability, project| ability.can?(:read, project.tickets.build) }
end

Houston.add_project_feature :testing do
  name "Testing"
  icon "fa-comments"
  path { |project| Houston::Application.routes.url_helpers.project_testing_report_path(project) }
end

Houston.add_project_feature :releases do
  name "Releases"
  icon "fa-paper-plane"
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
  icon "fa-gear"
  path { |project| Houston::Application.routes.url_helpers.edit_project_path(project) }
  ability { |ability, project| ability.can?(:update, project) }
end



Houston.add_project_option "testingReport.minPassingVerdicts" do
  name "Min. Passing Verdicts"
  html do |f|
    <<-HTML
    #{f.text_field :"testingReport.minPassingVerdicts", class: "text_field"}
    HTML
  end
end

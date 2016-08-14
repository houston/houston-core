module NavigationHelper

  def render_navigation(key)
    renderer = Houston.get_navigation_renderer(key)
    return unless renderer.permitted?(current_ability)

    render_nav_link renderer.name, renderer.path
  rescue KeyError
    Rails.logger.error "\e[31;1mThere is no navigation renderer named #{key.inspect}\e[0m"
    nil
  end

  def current_feature
    return nil unless current_project && current_project.persisted?
    @current_feature ||= current_project.features.find do |feature|
      current_page? feature_path(current_project, feature)
    end
  end

  def render_nav_for_feature(feature)
    feature = Houston.get_project_feature feature
    return unless feature.permitted?(current_ability, current_project)

    render_nav_link feature.name, feature.project_path(current_project)
  rescue KeyError
    Rails.logger.error "\e[31;1mThere is no project feature named #{feature.inspect}\e[0m"
    nil
  end

  def render_nav_menu(name, items: [])
    items.flatten!

    return "" if items.empty?

    <<-HTML.html_safe
    <li class="dropdown">
      <a href="#" title="#{h name}" class="dropdown-toggle" data-toggle="dropdown">
        #{h name} <b class="caret"></b>
      </a>
      <ul class="dropdown-menu releases-menu">
        #{items.map(&:to_html).join("")}
      </ul>
    </li>
    HTML
  end

  def render_nav_link(name, href)
    if current_page? href
      "<li class=\"current\">#{h name}</li>".html_safe
    else
      "<li><a href=\"#{href}\" title=\"#{h name}\">#{h name}</a></li>".html_safe
    end
  end

end

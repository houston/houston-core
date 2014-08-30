module NavigationHelper
  
  def render_navigation(key)
    renderer = Houston.config.get_navigation_renderer(key)
    instance_eval &renderer
  rescue KeyError
    Rails.logger.error "\e[31;1mThere is no navigation renderer named #{key.inspect}\e[0m"
    nil
  end
  
  def render_nav_menu(name, items: [], icon: "fa-circle-thin")
    items.flatten!
    
    return "" if items.empty?
    
    <<-HTML.html_safe
    <li class="dropdown">
      <a href="#" title="#{h name}" class="dropdown-toggle" data-toggle="dropdown">
        #{_render_nav(name, icon: icon)} <b class="caret"></b>
      </a>
      <ul class="dropdown-menu releases-menu">
        #{items.map(&:to_html).join("")}
      </ul>
    </li>
    HTML
  end
  
  def render_nav_link(name, href, icon: "fa-circle-thin")
    "<li><a href=\"#{href}\" title=\"#{h name}\">#{_render_nav(name, icon: icon)}</a></li>".html_safe
  end
  
private
  
  def _render_nav(name, icon: "fa-circle-thin")
    <<-HTML
    <div class="nav-icon">#{_nav_icon(icon)}</div>
    <span class="nav-label">#{h name}</span>
    HTML
  end
  
  def _nav_icon(icon)
    ($icons ||= {})[icon] ||= File.read(Rails.root.join("public", "icons", "#{icon}.svg"))
  end
  
end

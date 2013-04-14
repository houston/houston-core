module NavigationHelper
  
  def render_menu(name, menu_items)
    menu_items.flatten!
    
    return "" if menu_items.empty?
    
    html = <<-HTML
    <li class="dropdown">
      <a href="#" class="dropdown-toggle" data-toggle="dropdown">#{h name} <b class="caret"></b></a>
      <ul class="dropdown-menu releases-menu">
        #{menu_items.map(&:to_html).join("")}
      </ul>
    </li>
    HTML
    
    html.html_safe
  end
  
end

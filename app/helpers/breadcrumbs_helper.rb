module BreadcrumbsHelper
  
  def breadcrumbs(breadcrumbs={})
    html_safe <<-HTML
      <h3 class="breadcrumbs">
        <ul class="nav nav-pills">
          #{render_breadcrumbs(breadcrumbs)}
        </ul>
      </h3>
    HTML
  end
  
  def render_breadcrumbs(breadcrumbs)
    html = ""
    breadcrumbs.each_with_index do |(name, value), index|
      active = (index + 1) == breadcrumbs.length
      html << render_breadcrumb(active, name, value)
    end
    html
  end
  
  def render_breadcrumb(active, name, value=nil)
    puts "active: #{active}, name: #{name}, value: #{value} (#{value.class})"
    if value.nil?
      render_selected_breadcrumb(active, name)
    elsif value.is_a?(Array)
      if value.length <= 1
        render_breadcrumb_option(name, active)
      else
        render_dropdown_breadcrumb(active, name, value)
      end
    else
      render_simple_breadcrumb(active, name, value)
    end
  end
  
  def render_dropdown_breadcrumb(active, model, options)
    <<-HTML
    <li class="dropdown #{"active" if active}">
      <a class="dropdown-toggle" data-toggle="dropdown" href="#">#{model.name} <b class="caret"></b></a>
      <ul class="dropdown-menu">
        
        #{options.map(&method(:render_breadcrumb_option)).join}
      </ul>
    </li>
    HTML
  end
  
  def render_breadcrumb_option(model, active=false)
    "<li class=\"#{"active" if active}\"><a href=\"#{url_for(model)}\">#{model.name}</a></li>"
  end
  
  def render_simple_breadcrumb(active, name, url)
    "<li class=\"#{"active" if active}\"><a href=\"#{url}\">#{name}</a></li>"
  end
  
  def render_selected_breadcrumb(active, name)
    "<li class=\"#{"active" if active}\"><a>#{name}</a></li>"
  end
  
end

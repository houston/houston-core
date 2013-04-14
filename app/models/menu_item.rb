class MenuItem
  include ERB::Util
  
  def initialize(name, href)
    @name = name
    @href = href
  end
  
  attr_reader :href
  
  def display
    h @name
  end
  
  def to_html
    "<li><a href=\"#{href}\">#{display}</a></li>".html_safe
  end
  
end


class MenuItemDivider < MenuItem

  def initialize
    super("", "")
  end
  
  def to_html
    "<li class=\"divider\"></li>"
  end

end


class ProjectMenuItem < MenuItem
  
  def initialize(project, href)
    @project = project
    super(project.name, href)
  end
  
  def display
    "#{h @project.name} <b class=\"bubble #{h @project.color}\"></b>".html_safe
  end
  
end

class ProjectMenuItem < MenuItem
  
  def initialize(project, href)
    @project = project
    super(project.name, href)
  end
  
  def display
    "#{h @project.name} <b class=\"bubble #{h @project.color}\"></b>".html_safe
  end
  
end

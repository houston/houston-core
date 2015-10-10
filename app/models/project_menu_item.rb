class ProjectMenuItem < MenuItem

  def initialize(project, href)
    @project = project
    super(project.name, href)
  end

  def display
    "<b class=\"bubble #{h @project.color}\"></b> #{h @project.name}".html_safe
  end

end

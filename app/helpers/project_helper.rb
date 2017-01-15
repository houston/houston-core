module ProjectHelper

  def project_label(project)
    return '<b class="label unknown">&nbsp;</b>'.html_safe unless project
    "<b class=\"label #{project.color}\">#{h project.slug.gsub("_", " ")}</b>".html_safe
  end

end

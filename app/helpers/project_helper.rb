module ProjectHelper

  def project_label(project)
    return '<b class="label unknown">&nbsp;</b>'.html_safe unless project
    "<b class=\"label #{project.color}\">#{h project.slug.gsub("_", " ")}</b>".html_safe
  end

  def project_banner(project, &block)
    content_for :title do
      content_tag :h1, class: "project-banner #{project.color} space-below", "data-project-slug" => project.slug, "data-project-color" => project.color, &block
    end
  end

end

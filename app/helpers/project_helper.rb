module ProjectHelper

  def with_most_recent_commit(project)
    commit = project.head
    if commit
      commit.project = project # so that _Commit_ doesn't load project again
      yield commit
    end
  end

  def project_label(project)
    return '<b class="label unknown">&nbsp;</b>'.html_safe unless project
    "<b class=\"label #{project.color}\">#{h project.slug.gsub("_", " ")}</b>".html_safe
  end

end

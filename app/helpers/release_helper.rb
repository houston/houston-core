module ReleaseHelper
  
  def format_release_date(release)
    if release
      release.created_at.strftime("%A, %b %e, %Y")
    else
      "&mdash;".html_safe
    end
  end
  
end

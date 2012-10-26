module ReleaseHelper
  
  def format_release_date(release)
    if release
      release.created_at.strftime("%A, %b %e, %Y")
    else
      "&mdash;".html_safe
    end
  end
  
  def format_release_age(release)
    if release
      distance_of_time_in_words(Time.now - release.created_at) + " ago"
    else
      "&mdash;".html_safe
    end
  end
  
end

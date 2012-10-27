module ReleaseHelper
  
  def format_release_date(date)
    "<span class=\"weekday\">#{date.strftime("%A")}</span> #{date.strftime("%b %e, %Y")}".html_safe
  end
  
  def format_release_age(release)
    if release
      distance_of_time_in_words(Time.now - release.created_at) + " ago"
    else
      "&mdash;".html_safe
    end
  end
  
end

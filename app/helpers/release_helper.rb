module ReleaseHelper
  
  def format_release_date(date)
    "<span class=\"weekday\">#{date.strftime("%A")}</span> #{date.strftime("%b %e, %Y")}".html_safe
  end
  
  def ordered_by_tag(changes)
    changes.sort_by { |change| change.tag ? change.tag.position : 99 }
  end
  
  def format_release_age(release)
    if release
      distance_of_time_in_words(release.created_at, Time.now) + " ago"
    else
      "&mdash;".html_safe
    end
  end
  
  def replace_quotes(string)
    h(string).gsub(/&quot;(.+?)&quot;/, '<code>\1</code>').html_safe
  end
  
  def format_change_tag(tag)
    "<div class=\"change-tag\" style=\"background-color: ##{tag.color};\">#{tag.name}</div>".html_safe
  end
  
end

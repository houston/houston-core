module ReleaseHelper
  
  def format_release_date(date)
    "<span class=\"weekday\">#{date.strftime("%A")}</span> #{date.strftime("%b %e, %Y")}".html_safe
  end
  
  def ordered_by_tag(changes)
    changes.sort_by { |change| change.tag ? change.tag.position : 99 }
  end
  
  def format_release_age(release)
    format_time_ago release && release.created_at
  end
  
  def format_time_ago(time)
    return "&mdash;".html_safe unless time
    "<span class=\"friendly-duration\">#{_format_time_ago(time)}</span>".html_safe
  end
  
  def _format_time_ago(time)
    duration = (Time.now - time).to_i
    return "#{duration} seconds ago" if duration < 90.seconds
    return "#{duration / 60} minutes ago" if duration < 90.minutes
    return "%.1f hours ago" % (duration / 3600.0) if duration < 20.hours

    days = (duration / 86400.0).round
    return "1 day ago" if days == 1
    return "#{days} days ago" if days < 21
    return "#{days / 7} weeks ago" if days < 63
    return "#{days / 30} months ago" if days < 456
    return ">1 year ago" if days < 730
    return ">#{days / 365} years ago"
  end
  
  def replace_quotes(string)
    h(string).gsub(/&quot;(.+?)&quot;/, '<code>\1</code>').html_safe
  end
  
  def format_change(change)
    mdown change.description
  end
  
  def format_change_tag(tag)
    "<div class=\"change-tag\" style=\"background-color: ##{tag.color};\">#{tag.name}</div>".html_safe
  end
  
end

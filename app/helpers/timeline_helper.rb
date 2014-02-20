module TimelineHelper
  
  def render_timeline_gap_for(date_range)
    days = date_range.end - date_range.begin
    if days < 3
      date_range.inject("") { |html, date| html << render_timeline_date(date) }.html_safe
    else
      <<-HTML.html_safe
      <div class="timeline-date-gap"></div>
      #{render_timeline_date(date_range.begin)}
      HTML
    end
  end
  
  def icon_for_resolution(resolution)
    case resolution
    when nil, "", "fixed" then "icon-ok"
    else "icon-trash"
    # when "duplicate" then "icon-tags"
    # when "invalid" then "icon-ban-circle"
    # else "icon-trash"
    end
  end
  
  def render_timeline_date(date)
    <<-HTML.html_safe
    <div class="timeline-date">
      <span class="weekday">#{date.strftime("%a")}</span>
      <span class="month">#{date.strftime("%b")}</span>
      <span class="day">#{date.strftime("%e")}</span>
      <span class="year">#{date.strftime("%Y")}</span>
    </div>
    HTML
  end
  
end

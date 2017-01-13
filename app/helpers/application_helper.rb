module ApplicationHelper

  def title
    @title || Houston.config.title
  end

  def revision
    controller.revision
  end

  def html_safe(html)
    html.html_safe
  end

  def header
    yield PageHeaderBuilder.new(self)
    "<hr class=\"clear\" />".html_safe
  end

  def custom_link_unless_current(link_text, url)
    "<li>#{link_to(link_text, url)}</li>".html_safe unless current_page?(url)
  end

  def google_analytics_script_tag
    id = Houston.config.google_analytics[:tracking_id]
    return nil if id.blank?
    return "<!-- Google Analytics for #{id.inspect} in Production -->".html_safe unless Rails.env.production?
    <<-HTML.html_safe
    <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
      ga('create', #{id.inspect}, 'auto');
      ga('send', 'pageview');
    </script>
    HTML
  end



  def in_columns(collection, options={}, &block)
    max_size = options.fetch(:max_size, 10)
    column_count = (collection.length.to_f / max_size).ceil
    column_count = 1 if column_count < 1
    in_columns_of(collection, column_count, &block)
  end

  def in_groups_of(collection, column_count, css_class="column")
    html = collection.in_groups_of(column_count).each_with_object("") do |items_in_column, html|
      html << "<div class=\"#{css_class}\">"
      items_in_column.compact.each do |item|
        html << capture { yield (item) }
      end
      html << "</div>"
    end
    html.html_safe
  end

  alias :in_columns_of :in_groups_of



  def format_time(time, options={})
    if time.nil?
      date, time = ["", "Never"]
    elsif time.to_date == Date.today
      date, time = [options[:today] ? "Today" : "", time.strftime("%l:%M %p")]
    elsif time.to_date == Date.today - 1
      date, time = ["Yesterday", time.strftime("%l:%M %p")]
    else
      date, time = [time.strftime("%b %e"), time.strftime("%l:%M %p")]
    end

    <<-HTML.strip.html_safe
    <span class="time-date">#{date}</span>
    <span class="time-time">#{time.gsub(" AM", "a").gsub(" PM", "p")}</span>
    HTML
  end

  def format_boolean(boolean)
    if boolean
      '<i class="fa fa-check success"></i>'.html_safe
    else
      '<i class="fa fa-times failure"></i>'.html_safe
    end
  end

  def format_action_state(job)
    if job.in_progress?
      '<i class="fa fa-spinner fa-pulse"></i>'.html_safe
    elsif job.succeeded?
      '<i class="fa fa-check success"></i>'.html_safe
    else
      '<i class="fa fa-times failure"></i>'.html_safe
    end
  end

  MINUTE = 60
  HOUR = MINUTE * 60
  DAY = HOUR * 24

  def format_duration(seconds)
    if seconds.nil?
      return "&mdash;".html_safe
    elsif seconds < 1
      "#{(seconds * 1000).floor}ms"
    elsif seconds < MINUTE
      "%.2f seconds" % seconds
    elsif seconds < HOUR
      format_duration_with_units(seconds / MINUTE, 'minute')
    elsif seconds < DAY
      format_duration_with_units(seconds / HOUR, 'hour')
    else
      format_duration_with_units(seconds / DAY, 'day')
    end
  end

  def format_duration_with_units(quantity, unit)
    quantity = quantity.floor
    unit << 's' unless quantity == 1
    "#{quantity} #{unit}"
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



  def format_date_with_year(date)
    return "" if date.nil?
    "#{date.strftime("%b %d")}<span class=\"year\">#{date.strftime("%Y")}</span>".html_safe
  end



  def follows?(project)
    followed_projects.member?(project)
  end



  def pull_request_label(label)
    background = "##{label["color"]}"
    foreground = "#fff"
    foreground = "#333" if %w{#f7c6c7 #d4c5f9 #fbca04 #fad8c7 #bfe5bf}.member? background
    "<span class=\"label\" style=\"background: #{background}; color: #{foreground};\">#{label["name"]}</span>".html_safe
  end


end


class PageHeaderBuilder

  def initialize(context)
    @context = context
  end

  delegate :breadcrumbs, :capture, :to => :@context

  def actions(&block)
    html_safe "<div class=\"page-actions\">#{capture(&block)}</div>"
  end

  def html_safe(html)
    html.html_safe
  end

end

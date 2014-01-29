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
  
  
  
  def format_time(time)
    if time.nil?
      date, time = ["", "Never"]
    elsif time.to_date == Date.today
      date, time = ["Today", time.strftime("%l:%M %p")]
    elsif time.to_date == Date.today - 1
      date, time = ["Yesterday", time.strftime("%l:%M %p")]
    else
      date, time = [time.strftime("%b %e"), time.strftime("%l:%M %p")]
    end
    
    <<-HTML.html_safe
    <span class="time-date">#{date}</span>
    <span class="time-time">#{time.gsub(" AM", "a").gsub(" PM", "p")}</span>
    HTML
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

module ApplicationHelper
  
  def title
    @title || Rails.configuration.title
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
    "| #{link_to(link_text, url)}".html_safe unless current_page?(url)
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

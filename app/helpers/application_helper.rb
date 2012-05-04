module ApplicationHelper
  
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

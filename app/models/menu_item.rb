class MenuItem
  include ERB::Util

  def initialize(name, href)
    @name = name
    @href = href
  end

  attr_reader :href

  def display
    h @name
  end

  def to_html
    "<li><a href=\"#{href}\">#{display}</a></li>".html_safe
  end

end

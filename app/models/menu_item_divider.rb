class MenuItemDivider < MenuItem

  def initialize
    super("", "")
  end
  
  def to_html
    "<li class=\"divider\"></li>"
  end

end

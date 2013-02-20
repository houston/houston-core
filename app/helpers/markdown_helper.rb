module MarkdownHelper
  
  def mdown(text)
    emojify BlueCloth::new(text).to_html.html_safe
  end
  
end

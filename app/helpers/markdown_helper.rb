module MarkdownHelper
  
  def mdown(text)
    BlueCloth::new(text).to_html.html_safe
  end
  
end

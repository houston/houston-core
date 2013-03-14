module MarkdownHelper
  include EmojiHelper
  
  def markdown
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      :autolink => true,
      :no_intra_emphasis => true)
  end
  
  def mdown(text)
    return "" if text.blank?
    emojify markdown.render(text).html_safe
  end
  
end

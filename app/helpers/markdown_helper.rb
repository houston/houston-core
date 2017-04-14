module MarkdownHelper
  include EmojiHelper

  def mdown(text)
    return "" if text.blank?
    emojify Kramdown::Document.new(text).to_html.html_safe
  end

  def slackdown(text)
    Slackdown.convert(text)
  end

end

module EmojiHelper

  def emojify(content)
    content.to_str.gsub(/:([a-z0-9\+\-_]+):/) do |match|
      if Emoji.all.map(&:name).include?($1)
        "<img alt=\"#{$1}\" height=\"20\" width=\"20\" src=\"#{image_url("emoji/#{$1}.png")}\" class=\"emoji\" />"
      else
        match
      end
    end.html_safe if content.present?
  end
  
end

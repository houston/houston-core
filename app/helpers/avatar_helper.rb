module AvatarHelper
  
  
  
  def avatar_for(user, options={})
    size = options.fetch(:size, 24)
    "<img src=\"#{gravatar_url(user, options)}\" width=\"#{size}\" height=\"#{size}\" alt=\"#{user.name}\" />".html_safe
  end
  
  
  # http://en.gravatar.com/site/implement/ruby
  # http://en.gravatar.com/site/implement/url
  def gravatar_url(user, options={})
    email = user.email
    url = "http://www.gravatar.com/avatar/#{Digest::MD5::hexdigest(email)}?r=g&d=identicon"
    url << "&s=#{options[:size]}" if options.key?(:size)
    url
  end
  
  
  
end
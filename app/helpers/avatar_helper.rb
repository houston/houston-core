module AvatarHelper
  
  
  
  def avatar_for(user, options={})
    return "" unless user
    
    size = options.fetch(:size, 24)
    "<img class=\"avatar user-#{user.id}\" src=\"#{gravatar_url(user.email, options)}\" width=\"#{size}\" height=\"#{size}\" alt=\"#{user.name}\" />".html_safe
  end
  
  
  def gravatar_image(email, options={})
    return "" if email.blank?
    
    size = options.fetch(:size, 24)
    alt = options[:alt]
    "<img class=\"avatar\" src=\"#{gravatar_url(email, options)}\" width=\"#{size}\" height=\"#{size}\" alt=\"#{alt}\" />".html_safe
  end
  
  
  # http://en.gravatar.com/site/implement/ruby
  # http://en.gravatar.com/site/implement/url
  def gravatar_url(email, options={})
    url = "http://www.gravatar.com/avatar/#{Digest::MD5::hexdigest(email)}?r=g&d=retro"
    url << "&s=#{options[:size] * 2}" if options.key?(:size)
    url
  end
  
  
  
end
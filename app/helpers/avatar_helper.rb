module AvatarHelper



  def avatar_for(user, options={})
    size = options.fetch(:size, 24)

    return "<div class=\"avatar avatar-empty\" style=\"width:#{size}px; height:#{size}px\"></div>".html_safe unless user

    "<img class=\"avatar user-#{user.id}\" src=\"#{gravatar_url(user.email, size: size * 2)}\" width=\"#{size}\" height=\"#{size}\" alt=\"#{user.name}\" />".html_safe
  end


  def gravatar_image(email, options={})
    return "" if email.blank?

    size = options.fetch(:size, 24)
    alt = options[:alt]
    "<img class=\"avatar\" src=\"#{gravatar_url(email, size: size * 2)}\" width=\"#{size}\" height=\"#{size}\" alt=\"#{alt}\" />".html_safe
  end


  # http://en.gravatar.com/site/implement/ruby
  # http://en.gravatar.com/site/implement/url
  def gravatar_url(email, options={})
    url = "https://www.gravatar.com/avatar/#{Digest::MD5::hexdigest(email)}?r=g&d=retro"
    url << "&s=#{options[:size]}" if options.key?(:size)
    url
  end



end

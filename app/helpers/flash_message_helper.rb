module FlashMessageHelper


  def flash_messages(*args)
    options = args.extract_options!
    args.inject("") {|html, key| html << flash_message(key, options.dup)}.html_safe
  end


  def flash_message(key, options={})
    message = flash[key].to_s
    klass = "alert-#{key}"
    klass = "alert-success" if key.to_s == "notice"
    klass = nil if key.to_s == "alert"
    options.reverse_merge!(:class => "alert #{klass}", :id => "flash_#{key}")
    options.merge!(:style => "display:none;") if message.empty?
    message = '<button type="button" class="close" data-dismiss="alert">&times;</button>'.html_safe + h(message)
    content_tag :div, message, options
  end


end

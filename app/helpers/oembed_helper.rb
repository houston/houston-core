module OembedHelper

  def link_to_oembed(url)
    url = "#{main_app.root_url}oembed/1.0?url=#{CGI.escape(url)}"
    tag "link", rel: "alternate", type: "application/json+oembed", href: url
  end

end

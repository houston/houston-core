module EmailHelper
  
  def render_scss(relative_path)
    path = Rails.root.join("app/assets/stylesheets", relative_path).to_s
    stylesheet = File.read(path)
    stylesheet = ERB.new(stylesheet).result(binding) if File.extname(relative_path) == ".erb"
    Sass::Engine.new(stylesheet, :syntax => :scss).render
  end
  
  def for_email?
    @for_email == true
  end
  
end

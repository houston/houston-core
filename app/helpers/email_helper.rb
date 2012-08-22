module EmailHelper
  
  def render_scss(relative_path)
    path = Rails.root.join("app/assets/stylesheets", relative_path).to_s
    sass_engine = Sass::Engine.for_file(path, :syntax => :scss)
    sass_engine.render
  end
  
  def for_email?
    @for_email == true
  end
  
end

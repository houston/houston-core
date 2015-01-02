module EmailHelper
  
  def render_scss(relative_path)
    asset = Rails.application.assets.find_asset(relative_path)
    raise "Asset not found #{relative_path.inspect}" unless asset
    asset.to_s.html_safe
  end
  
  def for_email?
    @for_email == true
  end
  
end

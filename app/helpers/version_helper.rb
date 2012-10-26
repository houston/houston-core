module VersionHelper
  
  
  def format_version(version)
    version.to_s.split(".").join('<span class="period">.</span>').html_safe
  end
  
  
end

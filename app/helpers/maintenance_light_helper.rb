module MaintenanceLightHelper
  
  def format_maintenance_light(arg, options={})
    maintenance_light = arg.respond_to?(:maintenance_light) ? arg.maintenance_light : arg
    return "&mdash;".html_safe if maintenance_light.nil?
    
    html = <<-HTML
    <span class="maintenance-light" rel="tooltip" title="#{maintenance_light.message}">
      <i class="stoplight #{maintenance_light.color}"></i>
      #{maintenance_light.dependency_name if options.fetch(:with_name, false)}
      #{maintenance_light.version}
    </span>
    HTML
    html.html_safe
  end
  
end

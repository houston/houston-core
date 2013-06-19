module DailyReportHelper
  
  
  def render_wip(project, wip)
    count, type = wip
    case type
    when :exceptions
      link_to_if(project.error_tracker.project_url, "#{pluralize count, "open exceptions"}", project.error_tracker.project_url, target: "_blank")
    end
  end
  
  
end

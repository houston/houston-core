module DailyReportHelper
  
  
  def render_wip(project, wip)
    count, type, url = wip
    link_to_if url, "#{pluralize count, type}", url, target: "_blank"
  end
  
  
end

class Unfuddle::TicketReportsController < UnfuddleController
  
  def index
    render_from_unfuddle "/projects/#{params[:project_id]}/ticket_reports"
  end
  
  def show
    render_from_unfuddle "/projects/#{params[:project_id]}/ticket_reports/#{params[:id]}/generate"
  end
  
end

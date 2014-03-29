class KanbanTicketPresenter
  include UrlHelper
  
  def initialize(tickets)
    @tickets = tickets
  end
  
  def as_json(*args)
    tickets = ActiveRecord::Base.benchmark "\e[33m[kanban_ticket_presenter] Load objects\e[0m" do
      @tickets.load
    end
    ActiveRecord::Base.benchmark "\e[33m[kanban_ticket_presenter] Prepare JSON\e[0m" do
      @tickets.map do |ticket|
        project = ticket.project
        { # generic
          id: ticket.id,
          projectId: project.id,
          projectSlug: project.slug,
          projectTitle: project.name,
          projectColor: project.color,
          ticketSystem: project.ticket_tracker_name,
          ticketUrl: ticket.ticket_tracker_ticket_url,
          number: ticket.number,
          summary: ticket.summary,
          type: ticket.type.to_s.downcase.dasherize,
          tags: ticket.tags.map(&:to_h),
        
          # specific to Kanban
          verdictsByTester: ticket.verdicts_by_tester_index,
          queues: ticket.age_in_queues }
      end
    end
  end
  
end

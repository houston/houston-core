class TicketPresenter
  include UrlHelper
  
  def initialize(tickets)
    @tickets = OneOrMany.new(tickets)
  end
  
  def as_json(*args)
    tickets = ActiveRecord::Base.benchmark "\e[33m[#{self.class.name.underscore}] Load objects\e[0m" do
      @tickets.load
    end
    ActiveRecord::Base.benchmark "\e[33m[#{self.class.name.underscore}] Prepare JSON\e[0m" do
      tickets.map(&method(:ticket_to_json))
    end
  end
  
  def ticket_to_json(ticket)
    project = ticket.project
    { id: ticket.id,
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
      extendedAttributes: ticket.extended_attributes }
  end
  
end
